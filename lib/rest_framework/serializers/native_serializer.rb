# This serializer uses `.serializable_hash` to convert objects to Ruby primitives (with the
# top-level being either an array or a hash).
class RESTFramework::Serializers::NativeSerializer < RESTFramework::Serializers::BaseSerializer
  EXTRACT_FROM_QUERY = ->(p, controller) {
    return Set[] if p.blank?
    (
      controller.request&.query_parameters&.[](p).presence&.split(",")&.map { |x|
        x.strip.presence
      }&.compact || []
    ).to_set
  }
  class_attribute :config
  class_attribute :singular_config
  class_attribute :plural_config
  class_attribute :action_config

  # Accept/ignore `*args` to be compatible with the `ActiveModel::Serializer#initialize` signature.
  def initialize(object = nil, *args, many: nil, model: nil, **kwargs)
    super(object, *args, **kwargs)

    if many.nil?
      # Determine if we are dealing with many objects or just one.
      @many = @object.is_a?(Enumerable)
    else
      @many = many
    end

    # Determine model either explicitly, or by inspecting @object or @controller.
    @model = model
    @model ||= @object.class if @object.is_a?(ActiveRecord::Base)
    @model ||= @object.klass if @many && @object.is_a?(ActiveRecord::Relation)
    @model ||= @object.first.class if @many &&
      @object.is_a?(Enumerable) &&
      @object.first.is_a?(ActiveRecord::Base)

    @model ||= @controller.class.model if @controller
  end

  def action
    @action ||= @controller&.action_name&.to_sym
  end

  def fields
    return @fields if defined?(@fields)
    return nil unless base_fields = @controller&.get_fields

    only_param = @controller.class.native_serializer_only_query_param
    except_param = @controller.class.native_serializer_except_query_param
    include_param = @controller.class.native_serializer_include_query_param
    exclude_param = @controller.class.native_serializer_exclude_query_param

    only = EXTRACT_FROM_QUERY.call(only_param, @controller)
    except = EXTRACT_FROM_QUERY.call(except_param, @controller)
    include = EXTRACT_FROM_QUERY.call(include_param, @controller)
    exclude = EXTRACT_FROM_QUERY.call(exclude_param, @controller)

    field_configuration = @controller.class.field_configuration
    @fields = base_fields.select do |f|
      cfg = field_configuration[f]

      # We never serialize write-only fields.
      next false if cfg[:write_only]

      # We never serialize `hidden_from_index` fields for collections as this is a performance
      # option.
      next false if cfg[:hidden_from_index] && @many

      # Explicitly excluded fields should never be serialized.
      next false if f.in?(except) || f.in?(exclude)

      # Hidden fields must be in `only` or `include` to be serialized; for non-hidden fields, either
      # `only` must be empty, or the field must be in `only` or `include`.
      if cfg[:hidden]
        next true if f.in?(only) || f.in?(include)
      elsif only.empty? || f.in?(only) || f.in?(include)
        next true
      end

      next false
    end

    @fields
  end

  def get_local_native_serializer_config
    if (action = self.action) && (cfg = action_config)
      # Index action should use :list serializer config if :index is not provided.
      action = :list if action == :index && !cfg.key?(:index)

      return cfg[action] if cfg[action]
    end

    # No action_config, so try singular/plural config if explicitly instructed to via @many.
    return self.plural_config if @many == true && self.plural_config
    return self.singular_config if @many == false && self.singular_config

    # Lastly, try returning the default config.
    self.config
  end

  # Get a native serializer configuration from the controller.
  def get_controller_native_serializer_config
    return nil unless @controller

    if @many == true
      controller_serializer = @controller.class.native_serializer_plural_config
    elsif @many == false
      controller_serializer = @controller.class.native_serializer_singular_config
    end

    controller_serializer || @controller.class.native_serializer_config
  end

  # Get the associations limit from the controller.
  def _associations_limit
    return @_associations_limit if defined?(@_associations_limit)

    limit = @controller&.class&.native_serializer_associations_limit
    max = @controller&.class&.native_serializer_associations_limit_max

    # If a max is configured, allow the query parameter to adjust the limit up to that max.
    if max && (query_param = @controller&.class&.native_serializer_associations_limit_query_param)
      if @controller.request.query_parameters.key?(query_param)
        query_limit = @controller.request.query_parameters[query_param].to_i
        limit = [ query_limit, max ].min if query_limit > 0
      end
    end

    @_associations_limit = limit
  end

  # Get a serializer configuration from the controller. `@controller` and `@model` must be set.
  def _get_controller_serializer_config
    columns = []
    includes = {}
    methods = []
    serializer_methods = {}

    # We try to construct performant queries using Active Record's `includes` method. This is
    # sometimes impossible, for example when limiting the number of associated records returned, so
    # we should only add associations here when it's useful, and using the `Bullet` gem is helpful
    # in determining when that is the case.
    includes_map = {}

    column_names = @model.column_names
    reflections = @model.reflections
    attachment_reflections = @model.attachment_reflections

    self.fields.each do |f|
      field_config = @controller.class.field_configuration[f]
      next if field_config[:write_only]

      if f.in?(column_names)
        columns << f
      elsif ref = reflections[f]
        sub_columns = []
        sub_methods = []
        field_config[:sub_fields].each do |sf|
          if !ref.polymorphic? && sf.in?(ref.klass.column_names)
            sub_columns << sf
          else
            sub_methods << sf
          end
        end
        sub_config = { only: sub_columns, methods: sub_methods }

        # Apply certain rules regarding collection associations.
        if ref.collection?
          # If we need to limit the number of serialized association records, then dynamically add a
          # serializer method to do so.
          if limit = self._associations_limit
            serializer_methods[f] = f
            self.define_singleton_method(f) do |record|
              next record.send(f).limit(limit).as_json(**sub_config)
            end

            # Disable this for now, as it's not clear if this improves performance of count.
            #
            # # Even though we use a serializer method, if the count will later be added, then put
            # # this field into the includes_map.
            # if @controller.class.native_serializer_include_associations_count
            #   includes_map[f] = f.to_sym
            # end
          else
            includes[f] = sub_config
            includes_map[f] = f.to_sym
          end

          # If we need to include the association count, then add it here.
          if @controller.class.native_serializer_include_associations_count
            method_name = "#{f}.count"
            serializer_methods[method_name] = method_name
            self.define_singleton_method(method_name) do |record|
              next record.send(f).count
            end
          end
        else
          includes[f] = sub_config
          includes_map[f] = f.to_sym
        end
      elsif @controller.class.enable_action_text && ref = reflections["rich_text_#{f}"]
        # ActionText Integration: Define rich text serializer method.
        includes_map[f] = :"rich_text_#{f}"
        serializer_methods[f] = f
        self.define_singleton_method(f) do |record|
          next record.send(f).to_s
        end
      elsif @controller.class.enable_active_storage && ref = attachment_reflections[f]
        # ActiveStorage Integration: Define attachment serializer method.
        if ref.macro == :has_one_attached
          serializer_methods[f] = f
          includes_map[f] = { "#{f}_attachment": :blob }
          self.define_singleton_method(f) do |record|
            attached = record.send(f)
            next attached.attachment ? {
              filename: attached.filename,
              signed_id: attached.signed_id,
              url: attached.url,
            } : nil
          end
        elsif ref.macro == :has_many_attached
          serializer_methods[f] = f
          includes_map[f] = { "#{f}_attachments": :blob }
          self.define_singleton_method(f) do |record|
            # Iterating the collection yields attachment objects.
            next record.send(f).map { |a|
              {
                filename: a.filename,
                signed_id: a.signed_id,
                url: a.url,
              }
            }
          end
        end
      elsif @model.method_defined?(f)
        methods << f
      else
        # Assume anything else is a virtual column.
        columns << f
      end
    end

    {
      only: columns,
      include: includes,
      methods: methods,
      serializer_methods: serializer_methods,
      includes_map: includes_map,
    }
  end

  # Get the raw serializer config, prior to any adjustments from the request.
  #
  # Use `deep_dup` on any class mutables (array, hash, etc) to avoid mutating class state.
  def get_raw_serializer_config
    # Return a locally defined serializer config if one is defined.
    if local_config = self.get_local_native_serializer_config
      return local_config.deep_dup
    end

    # Return a serializer config if one is defined on the controller.
    if serializer_config = self.get_controller_native_serializer_config
      return serializer_config.deep_dup
    end

    # If the config wasn't determined, build a serializer config from controller fields.
    if @model && self.fields
      return self._get_controller_serializer_config
    end

    # By default, pass an empty configuration, using the default Rails serializer.
    {}
  end

  # Get a configuration passable to `serializable_hash` for the object.
  def get_serializer_config
    self.get_raw_serializer_config
  end

  # Serialize a single record and merge results of `serializer_methods`.
  def _serialize(record, config, serializer_methods)
    # Ensure serializer_methods is either falsy, or a hash.
    if serializer_methods && !serializer_methods.is_a?(Hash)
      serializer_methods = [ serializer_methods ].flatten.map { |m| [ m, m ] }.to_h
    end

    # Merge serialized record with any serializer method results.
    record.serializable_hash(config).merge(
      serializer_methods&.map { |m, k| [ k.to_sym, self.send(m, record) ] }.to_h,
    )
  end

  def serialize(*args)
    config = self.get_serializer_config
    serializer_methods = config.delete(:serializer_methods)
    includes_map = config.delete(:includes_map)

    if @object.respond_to?(:to_ary)
      # Preload associations using `includes` to avoid N+1 queries. For now this also allows filter
      # backends to use associated data; perhaps it may be wise to have a system in place for
      # filters to preload their own associations?
      @object = @object.includes(*includes_map.values) if includes_map.present?

      return @object.map { |r| self._serialize(r, config, serializer_methods) }
    end

    self._serialize(@object, config, serializer_methods)
  end

  # Allow a serializer instance to be used as a hash directly in a nested serializer config.
  def [](key)
    @_nested_config ||= self.get_serializer_config
    @_nested_config[key]
  end

  def []=(key, value)
    @_nested_config ||= self.get_serializer_config
    @_nested_config[key] = value
  end

  # Allow a serializer class to be used as a hash directly in a nested serializer config.
  def self.[](key)
    @_nested_config ||= self.new.get_serializer_config
    @_nested_config[key]
  end

  def self.[]=(key, value)
    @_nested_config ||= self.new.get_serializer_config
    @_nested_config[key] = value
  end
end

# Alias for convenience.
RESTFramework::NativeSerializer = RESTFramework::Serializers::NativeSerializer
