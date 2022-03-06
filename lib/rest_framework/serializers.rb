# The base serializer defines the interface for all REST Framework serializers.
class RESTFramework::BaseSerializer
  attr_accessor :object

  def initialize(object=nil, controller: nil, **kwargs)
    @object = object
    @controller = controller
  end

  # The primary interface for extracting a native Ruby types. This works both for records and
  # collections.
  def serialize(**kwargs)
    raise NotImplementedError
  end

  # Synonym for `serializable_hash` or compatibility with ActiveModelSerializers.
  def serializable_hash(**kwargs)
    return self.serialize(**kwargs)
  end
end

# This serializer uses `.serializable_hash` to convert objects to Ruby primitives (with the
# top-level being either an array or a hash).
class RESTFramework::NativeSerializer < RESTFramework::BaseSerializer
  class_attribute :config
  class_attribute :singular_config
  class_attribute :plural_config
  class_attribute :action_config

  def initialize(object=nil, many: nil, model: nil, **kwargs)
    super(object, **kwargs)

    if many.nil?
      # Determine if we are dealing with many objects or just one.
      @many = @object.is_a?(Enumerable)
    else
      @many = many
    end

    # Determine model either explicitly, or by inspecting @object or @controller.
    @model = model
    @model ||= @object.class if @object.is_a?(ActiveRecord::Base)
    @model ||= @object[0].class if
      @many && @object.is_a?(Enumerable) && @object.is_a?(ActiveRecord::Base)

    @model ||= @controller.send(:get_model) if @controller
  end

  # Get controller action, if possible.
  def get_action
    return @controller&.action_name&.to_sym
  end

  # Get a locally defined native serializer configuration, if one is defined.
  def get_local_native_serializer_config
    action = self.get_action

    if action && self.action_config
      # Index action should use :list serializer config if :index is not provided.
      action = :list if action == :index && !self.action_config.key?(:index)

      return self.action_config[action] if self.action_config[action]
    end

    # No action_config, so try singular/plural config if explicitly instructed to via @many.
    return self.plural_config if @many == true && self.plural_config
    return self.singular_config if @many == false && self.singular_config

    # Lastly, try returning the default config, or singular/plural config in that order.
    return self.config || self.singular_config || self.plural_config
  end

  # Helper to get a native serializer configuration from the controller.
  def get_controller_native_serializer_config
    return nil unless @controller

    if @many == true
      controller_serializer = @controller.class.try(:native_serializer_plural_config)
    elsif @many == false
      controller_serializer = @controller.class.try(:native_serializer_singular_config)
    end

    return controller_serializer || @controller.class.try(:native_serializer_config)
  end

  # Helper to filter (mutate) a single subconfig for specific keys.
  def self.filter_subconfig(subconfig, except, additive: false)
    return subconfig if !subconfig && !additive

    if subconfig.is_a?(Array)
      subconfig = subconfig.map(&:to_sym)
      if additive
        # Only add fields which are not already included.
        subconfig += except - subconfig
      else
        subconfig -= except
      end
    elsif subconfig.is_a?(Hash)
      # Additive doesn't make sense in a hash context since we wouldn't know the values.
      unless additive
        subconfig.symbolize_keys!
        subconfig.reject! { |k, _v| k.in?(except) }
      end
    elsif !subconfig
    else  # Subconfig is a single element (assume string/symbol).
      subconfig = subconfig.to_sym
      if subconfig.in?(except)
        subconfig = [] unless additive
      elsif additive
        subconfig = [subconfig, *except]
      end
    end

    return subconfig
  end

  # Helper to filter out configuration properties based on the :except query parameter.
  def filter_except(config)
    return config unless @controller

    except_query_param = @controller.class.try(:native_serializer_except_query_param)
    if except = @controller.request.query_parameters[except_query_param].presence
      except = except.split(",").map(&:strip).map(&:to_sym)

      unless except.empty?
        # Duplicate the config to avoid mutating class state.
        config = config.deep_dup

        # Filter `only`, `except` (additive), `include`, and `methods`.
        config[:only] = self.class.filter_subconfig(config[:only], except)
        config[:except] = self.class.filter_subconfig(config[:except], except, additive: true)
        config[:include] = self.class.filter_subconfig(config[:include], except)
        config[:methods] = self.class.filter_subconfig(config[:methods], except)
      end
    end

    return config
  end

  # Get the raw serializer config.
  def _get_raw_serializer_config
    # Return a locally defined serializer config if one is defined.
    if local_config = self.get_local_native_serializer_config
      return local_config
    end

    # Return a serializer config if one is defined on the controller.
    if serializer_config = self.get_controller_native_serializer_config
      return serializer_config
    end

    # If the config wasn't determined, build a serializer config from model fields.
    fields = @controller.send(:get_fields) if @controller
    if fields
      if @model
        columns, methods = fields.partition { |f| f.in?(@model.column_names) }
      else
        columns = fields
        methods = []
      end

      return {only: columns, methods: methods}
    end

    # By default, pass an empty configuration, allowing the serialization of all columns.
    return {}
  end

  # Get a configuration passable to `serializable_hash` for the object, filtered if required.
  def get_serializer_config
    return filter_except(self._get_raw_serializer_config)
  end

  def serialize(**kwargs)
    if @object.respond_to?(:to_ary)
      return @object.map { |r| r.serializable_hash(self.get_serializer_config) }
    end

    return @object.serializable_hash(self.get_serializer_config)
  end

  # Allow a serializer instance to be used as a hash directly in a nested serializer config.
  def [](key)
    @_nested_config ||= self.get_serializer_config
    return @_nested_config[key]
  end

  def []=(key, value)
    @_nested_config ||= self.get_serializer_config
    return @_nested_config[key] = value
  end

  # Allow a serializer class to be used as a hash directly in a nested serializer config.
  def self.[](key)
    @_nested_config ||= self.new.get_serializer_config
    return @_nested_config[key]
  end

  def self.[]=(key, value)
    @_nested_config ||= self.new.get_serializer_config
    return @_nested_config[key] = value
  end
end

# :nocov:
# Alias NativeModelSerializer -> NativeSerializer.
class RESTFramework::NativeModelSerializer < RESTFramework::NativeSerializer
  def initialize(**kwargs)
    super
    ActiveSupport::Deprecation.warn(
      <<~MSG.split("\n").join(" "),
        RESTFramework::NativeModelSerializer is deprecated and will be removed in future versions of
        REST Framework; you should use RESTFramework::NativeSerializer instead.
      MSG
    )
  end
end
# :nocov:

# This is a helper factory to wrap an ActiveModelSerializer to provide a `serialize` method which
# accepts both collections and individual records. Use `.for` to build adapters.
class RESTFramework::ActiveModelSerializerAdapterFactory
  def self.for(active_model_serializer)
    return Class.new(active_model_serializer) do
      def serialize
        if self.object.respond_to?(:to_ary)
          return self.object.map { |r| self.class.superclass.new(r).serializable_hash }
        end

        return self.serializable_hash
      end
    end
  end
end
