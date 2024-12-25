# This module provides the core functionality for controllers based on models.
module RESTFramework::Mixins::BaseModelControllerMixin
  BASE64_REGEX = /data:(.*);base64,(.*)/
  BASE64_TRANSLATE = ->(field, value) {
    return value unless BASE64_REGEX.match?(value)

    _, content_type, payload = value.match(BASE64_REGEX).to_a
    return {
      io: StringIO.new(Base64.decode64(payload)),
      content_type: content_type,
      filename: "file_#{field}#{Rack::Mime::MIME_TYPES.invert[content_type]}",
    }
  }
  ACTIVESTORAGE_KEYS = [:io, :content_type, :filename, :identify, :key]

  include RESTFramework::BaseControllerMixin

  RRF_BASE_MODEL_CONFIG = {
    # Core attributes related to models.
    model: nil,
    recordset: nil,

    # Attributes for configuring record fields.
    fields: nil,
    field_config: nil,

    # Attributes for finding records.
    find_by_fields: nil,
    find_by_query_param: "find_by",

    # Options for what should be included/excluded from default fields.
    exclude_associations: false,

    # Options for handling request body parameters.
    allowed_parameters: nil,
    filter_pk_from_request_body: true,
    exclude_body_fields: RESTFramework.config.exclude_body_fields,

    # Attributes for the default native serializer.
    native_serializer_config: nil,
    native_serializer_singular_config: nil,
    native_serializer_plural_config: nil,
    native_serializer_only_query_param: "only",
    native_serializer_except_query_param: "except",
    native_serializer_associations_limit: nil,
    native_serializer_associations_limit_query_param: "associations_limit",
    native_serializer_include_associations_count: false,

    # Attributes for filtering, ordering, and searching.
    filter_backends: [
      RESTFramework::QueryFilter,
      RESTFramework::OrderingFilter,
      RESTFramework::SearchFilter,
    ],
    filter_recordset_before_find: true,
    filter_fields: nil,
    ordering_fields: nil,
    ordering_query_param: "ordering",
    ordering_no_reorder: false,
    search_fields: nil,
    search_query_param: "search",
    search_ilike: false,
    ransack_options: nil,
    ransack_query_param: "q",
    ransack_distinct: true,
    ransack_distinct_query_param: "distinct",

    # Options for association assignment.
    permit_id_assignment: true,
    permit_nested_attributes_assignment: true,

    # Option for `recordset.create` vs `Model.create` behavior.
    create_from_recordset: true,
  }

  module ClassMethods
    IGNORE_VALIDATORS_WITH_KEYS = [:if, :unless].freeze

    def get_model
      return @model if @model
      return (@model = self.model) if self.model

      # Try to determine model from controller name.
      begin
        return @model = self.name.demodulize.chomp("Controller").singularize.constantize
      rescue NameError
      end

      raise RESTFramework::UnknownModelError, self
    end

    # Override to include ActiveRecord i18n-translated column names.
    def label_for(s)
      return self.get_model.human_attribute_name(s, default: super)
    end

    # Get the available fields. Fallback to this controller's model columns, or an empty array. This
    # should always return an array of strings.
    def get_fields(input_fields: nil)
      input_fields ||= self.fields

      # If fields is a hash, then parse it.
      if input_fields.is_a?(Hash)
        return RESTFramework::Utils.parse_fields_hash(
          input_fields,
          self.get_model,
          exclude_associations: self.exclude_associations,
          action_text: self.enable_action_text,
          active_storage: self.enable_active_storage,
        )
      elsif !input_fields
        # Otherwise, if fields is nil, then fallback to columns.
        model = self.get_model
        return model ? RESTFramework::Utils.fields_for(
          model,
          exclude_associations: self.exclude_associations,
          action_text: self.enable_action_text,
          active_storage: self.enable_active_storage,
        ) : []
      elsif input_fields
        input_fields = input_fields.map(&:to_s)
      end

      return input_fields
    end

    # Get a full field configuration, including defaults and inferred values.
    def field_configuration
      return @field_configuration if @field_configuration

      field_config = self.field_config&.with_indifferent_access || {}
      model = self.get_model
      columns = model.columns_hash
      column_defaults = model.column_defaults
      reflections = model.reflections
      attributes = model._default_attributes
      readonly_attributes = model.readonly_attributes
      exclude_body_fields = self.exclude_body_fields&.map(&:to_s)
      rich_text_association_names = model.reflect_on_all_associations(:has_one)
        .collect(&:name)
        .select { |n| n.to_s.start_with?("rich_text_") }
      attachment_reflections = model.attachment_reflections

      return @field_configuration = self.get_fields.map { |f|
        cfg = field_config[f]&.dup || {}
        cfg[:label] ||= self.label_for(f)

        # Annotate primary key.
        if model.primary_key == f
          cfg[:primary_key] = true

          unless cfg.key?(:readonly)
            cfg[:readonly] = true
          end
        end

        # Annotate readonly attributes.
        if f.in?(readonly_attributes) || f.in?(exclude_body_fields)
          cfg[:readonly] = true
        end

        # Annotate column data.
        if column = columns[f]
          cfg[:kind] = "column"
          cfg[:type] ||= column.type
          cfg[:required] = true unless column.null
        end

        # Add default values from the model's schema.
        if column_default = column_defaults[f] && !cfg[:default].nil?
          cfg[:default] ||= column_default
        end

        # Add metadata from the model's attributes hash.
        if attribute = attributes[f]
          if cfg[:default].nil? && default = attribute.value_before_type_cast
            cfg[:default] = default
          end
          cfg[:kind] ||= "attribute"

          # Get any type information from the attribute.
          if type = attribute.type
            cfg[:type] ||= type.type if type.type

            # Get enum variants.
            if type.is_a?(ActiveRecord::Enum::EnumType)
              cfg[:enum_variants] = type.send(:mapping)

              # TranslateEnum Integration:
              translate_method = "translated_#{f.pluralize}"
              if model.respond_to?(translate_method)
                cfg[:enum_translations] = model.send(translate_method)
              end
            end
          end
        end

        # Get association metadata.
        if ref = reflections[f]
          cfg[:kind] = "association"

          # Determine sub-fields for associations.
          if ref.polymorphic?
            ref_columns = {}
          else
            ref_columns = ref.klass.columns_hash
          end
          cfg[:sub_fields] ||= RESTFramework::Utils.sub_fields_for(ref)
          cfg[:sub_fields] = cfg[:sub_fields].map(&:to_s)

          # Very basic metadata about sub-fields.
          cfg[:sub_fields_metadata] = cfg[:sub_fields].map { |sf|
            v = {}

            if ref_columns[sf]
              v[:kind] = "column"
            else
              v[:kind] = "method"
            end

            next [sf, v]
          }.to_h.compact.presence

          # Determine if we render id/ids fields. Unfortunately, `has_one` does not provide this
          # interface.
          if self.permit_id_assignment && id_field = RESTFramework::Utils.id_field_for(f, ref)
            cfg[:id_field] = id_field
          end

          # Determine if we render nested attributes options.
          if self.permit_nested_attributes_assignment && (
            nested_opts = model.nested_attributes_options[f.to_sym].presence
          )
            cfg[:nested_attributes_options] = {field: "#{f}_attributes", **nested_opts}
          end

          begin
            cfg[:association_pk] = ref.active_record_primary_key
          rescue ActiveRecord::UnknownPrimaryKey
          end

          cfg[:reflection] = ref
        end

        # Determine if this is an ActionText "rich text".
        if :"rich_text_#{f}".in?(rich_text_association_names)
          cfg[:kind] = "rich_text"
        end

        # Determine if this is an ActiveStorage attachment.
        if ref = attachment_reflections[f]
          cfg[:kind] = "attachment"
          cfg[:attachment_type] = ref.macro
        end

        # Determine if this is just a method.
        if !cfg[:kind] && model.method_defined?(f)
          cfg[:kind] = "method"
        end

        # Collect validator options into a hash on their type, while also updating `required` based
        # on any presence validators.
        model.validators_on(f).each do |validator|
          kind = validator.kind
          options = validator.options

          # Reject validator if it includes keys like `:if` and `:unless` because those are
          # conditionally applied in a way that is not feasible to communicate via the API.
          next if IGNORE_VALIDATORS_WITH_KEYS.any? { |k| options.key?(k) }

          # Update `required` if we find a presence validator.
          cfg[:required] = true if kind == :presence

          # Resolve procs (and lambdas), and symbols for certain arguments.
          if options[:in].is_a?(Proc)
            options = options.merge(in: options[:in].call)
          elsif options[:in].is_a?(Symbol)
            options = options.merge(in: model.send(options[:in]))
          end

          cfg[:validators] ||= {}
          cfg[:validators][kind] ||= []
          cfg[:validators][kind] << options
        end

        next [f, cfg]
      }.to_h.with_indifferent_access
    end

    def openapi_schema
      return @openapi_schema if @openapi_schema

      field_configuration = self.field_configuration
      @openapi_schema = {
        required: field_configuration.select { |_, cfg| cfg[:required] }.keys,
        type: "object",
        properties: field_configuration.map { |f, cfg|
          v = {title: cfg[:label]}

          if cfg[:kind] == "association"
            v[:type] = cfg[:reflection].collection? ? "array" : "object"
          elsif cfg[:kind] == "rich_text"
            v[:type] = "string"
            v[:"x-rrf-rich_text"] = true
          elsif cfg[:kind] == "attachment"
            v[:type] = "string"
            v[:"x-rrf-attachment"] = cfg[:attachment_type]
          else
            v[:type] = cfg[:type]
          end

          v[:readOnly] = true if cfg[:readonly]
          v[:default] = cfg[:default] if cfg.key?(:default)

          if enum_variants = cfg[:enum_variants]
            v[:enum] = enum_variants.keys
            v[:"x-rrf-enum_variants"] = enum_variants
          end

          if validators = cfg[:validators]
            v[:"x-rrf-validators"] = validators
          end

          v[:"x-rrf-kind"] = cfg[:kind] if cfg[:kind]

          if cfg[:reflection]
            v[:"x-rrf-reflection"] = cfg[:reflection]
            v[:"x-rrf-association_pk"] = cfg[:association_pk]
            v[:"x-rrf-sub_fields"] = cfg[:sub_fields]
            v[:"x-rrf-sub_fields_metadata"] = cfg[:sub_fields_metadata]
            v[:"x-rrf-id_field"] = cfg[:id_field]
            v[:"x-rrf-nested_attributes_options"] = cfg[:nested_attributes_options]
          end

          next [f, v]
        }.to_h,
      }

      return @openapi_schema
    end

    def setup_delegation
      # Delegate extra actions.
      self.extra_actions&.each do |action, config|
        next unless config.is_a?(Hash) && config.dig(:metadata, :delegate)
        next unless self.get_model.respond_to?(action)

        self.define_method(action) do
          model = self.class.get_model

          if model.method(action).parameters.last&.first == :keyrest
            return api_response(model.send(action, **params))
          else
            return api_response(model.send(action))
          end
        end
      end

      # Delegate extra member actions.
      self.extra_member_actions&.each do |action, config|
        next unless config.is_a?(Hash) && config.dig(:metadata, :delegate)
        next unless self.get_model.method_defined?(action)

        self.define_method(action) do
          record = self.get_record

          if record.method(action).parameters.last&.first == :keyrest
            return api_response(record.send(action, **params))
          else
            return api_response(record.send(action))
          end
        end
      end
    end

    # Define any behavior to execute at the end of controller definition.
    # :nocov:
    def rrf_finalize
      super
      self.setup_delegation
      # self.setup_channel

      if RESTFramework.config.freeze_config
        self::RRF_BASE_MODEL_CONFIG.keys.each { |k|
          v = self.send(k)
          v.freeze if v.is_a?(Hash) || v.is_a?(Array)
        }
      end
    end
    # :nocov:
  end

  def self.included(base)
    RESTFramework::BaseControllerMixin.included(base)

    return unless base.is_a?(Class)

    base.extend(ClassMethods)

    # Add class attributes (with defaults) unless they already exist.
    RRF_BASE_MODEL_CONFIG.each do |a, default|
      next if base.respond_to?(a)

      base.class_attribute(a, default: default, instance_accessor: false)
    end
  end

  def get_fields
    return self.class.get_fields(input_fields: self.class.fields)
  end

  def openapi_metadata
    data = super
    routes = self.route_groups.values[0]
    schema_name = routes[0][:controller].camelize.gsub("::", ".")

    # Insert schema into metadata.
    data[:components] ||= {}
    data[:components][:schemas] ||= {}
    data[:components][:schemas][schema_name] = self.class.openapi_schema

    # Reference schema for specific actions with a `requestBody`.
    data[:paths].each do |_path, actions|
      actions.each do |_method, action|
        next unless action.is_a?(Hash)

        injectables = [action.dig(:requestBody, :content), *action[:responses].values.map { |r|
          r[:content]
        }].compact
        injectables.each do |i|
          i.each do |_, v|
            v[:schema] = {"$ref" => "#/components/schemas/#{schema_name}"}
          end
        end
      end
    end

    return data.merge(
      {
        "x-rrf-primary_key" => self.class.get_model.primary_key,
        "x-rrf-callbacks" => self._process_action_callbacks.as_json,
      },
    )
  end

  # Get a list of parameters allowed for the current action.
  def get_allowed_parameters
    return @_get_allowed_parameters if defined?(@_get_allowed_parameters)

    @_get_allowed_parameters = self.class.allowed_parameters
    return @_get_allowed_parameters if @_get_allowed_parameters

    # Assemble strong parameters.
    variations = []
    hash_variations = {}
    reflections = self.class.get_model.reflections
    @_get_allowed_parameters = self.get_fields.map { |f|
      f = f.to_s
      config = self.class.field_configuration[f]

      # ActionText Integration:
      if self.class.enable_action_text && reflections.key?("rich_test_#{f}")
        next f
      end

      # ActiveStorage Integration: `has_one_attached`
      if self.class.enable_active_storage && reflections.key?("#{f}_attachment")
        hash_variations[f] = ACTIVESTORAGE_KEYS
        next f
      end

      # ActiveStorage Integration: `has_many_attached`
      if self.class.enable_active_storage && reflections.key?("#{f}_attachments")
        hash_variations[f] = ACTIVESTORAGE_KEYS
        next nil
      end

      if config[:reflection]
        # Add `_id`/`_ids` variations for associations.
        if id_field = config[:id_field]
          if id_field.ends_with?("_ids")
            hash_variations[id_field] = []
          else
            variations << id_field
          end
        end

        # Add `_attributes` variations for associations.
        # TODO: Consider adjusting this based on `nested_attributes_options`.
        if self.class.permit_nested_attributes_assignment
          hash_variations["#{f}_attributes"] = (
            config[:sub_fields] + ["_destroy"]
          )
        end

        # Associations are not allowed to be submitted in their bare form (if they are submitted
        # that way, they will be translated to either id/ids or nested attributes assignment).
        next nil
      end

      next f
    }.compact
    @_get_allowed_parameters += variations
    @_get_allowed_parameters << hash_variations

    return @_get_allowed_parameters
  end

  def get_serializer_class
    return super || RESTFramework::NativeSerializer
  end

  # Use strong parameters to filter the request body using the configured allowed parameters.
  def get_body_params(bulk_mode: nil)
    data = self.request.request_parameters
    pk = self.class.get_model&.primary_key
    allowed_params = self.get_allowed_parameters

    # Before we filter the data, dynamically dispatch association assignment to either the id/ids
    # assignment ActiveRecord API or the nested assignment ActiveRecord API. Note that there is no
    # need to check for `permit_id_assignment` or `permit_nested_attributes_assignment` here, since
    # that is enforced by strong parameters generated by `get_allowed_parameters`.
    self.class.get_model.reflections.each do |name, ref|
      if payload = data[name]
        if payload.is_a?(Hash) || (payload.is_a?(Array) && payload.all? { |x| x.is_a?(Hash) })
          # Assume nested attributes assignment.
          attributes_key = "#{name}_attributes"
          data[attributes_key] = data.delete(name) unless data[attributes_key]
        elsif id_field = RESTFramework::Utils.id_field_for(name, ref)
          # Assume id/ids assignment.
          data[id_field] = data.delete(name) unless data[id_field]
        end
      end
    end

    # ActiveStorage Integration: Translate base64 encoded attachments to upload objects.
    #
    # rubocop:disable Layout/LineLength
    #
    # Example base64 images (red, green, and blue squares):
    #   data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mP8z8BQz0AEYBxVSF+FABJADveWkH6oAAAAAElFTkSuQmCC
    #   data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNk+M9Qz0AEYBxVSF+FAAhKDveksOjmAAAAAElFTkSuQmCC
    #   data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNkYPhfz0AEYBxVSF+FAP5FDvcfRYWgAAAAAElFTkSuQmCC
    #
    # rubocop:enable Layout/LineLength
    has_many_attached_scalar_data = {}
    if self.class.enable_active_storage
      self.class.get_model.attachment_reflections.keys.each do |k|
        if data[k].is_a?(Array)
          data[k] = data[k].map { |v|
            if v.is_a?(String)
              v = BASE64_TRANSLATE.call(k, v)

              # Remember scalars because Rails strong params will remove it.
              if v.is_a?(String)
                has_many_attached_scalar_data[k] ||= []
                has_many_attached_scalar_data[k] << v
              end
            elsif v.is_a?(Hash)
              if v[:io].is_a?(String)
                v[:io] = StringIO.new(Base64.decode64(v[:io]))
              end
            end

            next v
          }
        elsif data[k].is_a?(Hash)
          if data[k][:io].is_a?(String)
            data[k][:io] = StringIO.new(Base64.decode64(data[k][:io]))
          end
        elsif data[k].is_a?(String)
          data[k] = BASE64_TRANSLATE.call(k, data[k])
        end
      end
    end

    # Filter the request body with strong params. If `bulk` is true, then we apply allowed
    # parameters to the `_json` key of the request body.
    body_params = if allowed_params == true
      ActionController::Parameters.new(data).permit!
    elsif bulk_mode
      pk = bulk_mode == :update ? [pk] : []
      ActionController::Parameters.new(data).permit({_json: allowed_params + pk})
    else
      ActionController::Parameters.new(data).permit(*allowed_params)
    end

    # ActiveStorage Integration: Workaround for Rails strong params not allowing you to permit an
    # array containing a mix of scalars and hashes. This is needed for `has_many_attached`, because
    # API consumers must be able to provide scalar `signed_id` values for existing attachments along
    # with hashes for new attachments. It's worth mentioning that base64 scalars are converted to
    # hashes that conform to the ActiveStorage API.
    has_many_attached_scalar_data.each do |k, v|
      body_params[k].unshift(*v)
    end

    # Filter primary key, if configured.
    if self.class.filter_pk_from_request_body && bulk_mode != :update
      body_params.delete(pk)
    end

    # Filter fields in `exclude_body_fields`.
    (self.class.exclude_body_fields || []).each { |f| body_params.delete(f) }

    return body_params
  end
  alias_method :get_create_params, :get_body_params
  alias_method :get_update_params, :get_body_params

  # Get the set of records this controller has access to.
  def get_recordset
    return self.class.recordset if self.class.recordset

    # If there is a model, return that model's default scope (all records by default).
    if model = self.class.get_model
      return model.all
    end

    return nil
  end

  # Get the records this controller has access to *after* any filtering is applied.
  def get_records
    data = self.get_recordset

    return @records ||= self.class.filter_backends&.reduce(data) { |d, filter|
      filter.new(controller: self).filter_data(d)
    } || data
  end

  # Get a single record by primary key or another column, if allowed. The return value is memoized
  # and exposed to the view as the `@record` instance variable.
  def get_record
    return @record if @record

    find_by_key = self.class.get_model.primary_key
    is_pk = true

    # Find by another column if it's permitted.
    if find_by_param = self.class.find_by_query_param.presence
      if find_by = params[find_by_param].presence
        find_by_fields = self.class.find_by_fields&.map(&:to_s)

        if !find_by_fields || find_by.in?(find_by_fields)
          is_pk = false unless find_by_key == find_by
          find_by_key = find_by
        end
      end
    end

    # Get the recordset, filtering if configured.
    collection = if self.class.filter_recordset_before_find
      self.get_records
    else
      self.get_recordset
    end

    # Return the record. Route key is always `:id` by Rails' convention.
    if is_pk
      return @record = collection.find(request.path_parameters[:id])
    else
      return @record = collection.find_by!(find_by_key => request.path_parameters[:id])
    end
  end

  # Determine what collection to call `create` on.
  def get_create_from
    if self.class.create_from_recordset
      # Create with any properties inherited from the recordset. We exclude any `select` clauses
      # in case model callbacks need to call `count` on this collection, which typically raises a
      # SQL `SyntaxError`.
      self.get_recordset.except(:select)
    else
      # Otherwise, perform a "bare" insert_all.
      self.class.get_model
    end
  end

  # Serialize the records, but also include any errors that might exist. This is used for bulk
  # actions, however we include it here so the helper is available everywhere.
  def bulk_serialize(records)
    # This is kinda slow, so perhaps we should eventually integrate `errors` serialization into
    # the serializer directly. This would fail for active model serializers, but maybe we don't
    # care?
    s = RESTFramework::Utils.wrap_ams(self.get_serializer_class)
    return records.map do |record|
      s.new(record, controller: self).serialize.merge!({errors: record.errors.presence}.compact)
    end
  end
end

# Mixin for listing records.
module RESTFramework::Mixins::ListModelMixin
  def index
    return api_response(self.get_index_records)
  end

  # Get records with both filtering and pagination applied.
  def get_index_records
    records = self.get_records

    # Handle pagination, if enabled.
    if paginator_class = self.class.paginator_class
      # Paginate if there is a `max_page_size`, or if there is no `page_size_query_param`, or if the
      # page size is not set to "0".
      max_page_size = self.class.max_page_size
      page_size_query_param = self.class.page_size_query_param
      if max_page_size || !page_size_query_param || params[page_size_query_param] != "0"
        paginator = paginator_class.new(data: records, controller: self)
        page = paginator.get_page
        serialized_page = self.serialize(page)
        return paginator.get_paginated_response(serialized_page)
      end
    end

    return records
  end
end

# Mixin for showing records.
module RESTFramework::Mixins::ShowModelMixin
  def show
    return api_response(self.get_record)
  end
end

# Mixin for creating records.
module RESTFramework::Mixins::CreateModelMixin
  def create
    return api_response(self.create!, status: :created)
  end

  # Perform the `create!` call and return the created record.
  def create!
    return self.get_create_from.create!(self.get_create_params)
  end
end

# Mixin for updating records.
module RESTFramework::Mixins::UpdateModelMixin
  def update
    return api_response(self.update!)
  end

  # Perform the `update!` call and return the updated record.
  def update!
    record = self.get_record
    record.update!(self.get_update_params)
    return record
  end
end

# Mixin for destroying records.
module RESTFramework::Mixins::DestroyModelMixin
  def destroy
    self.destroy!
    return api_response("")
  end

  # Perform the `destroy!` call and return the destroyed (and frozen) record.
  def destroy!
    return self.get_record.destroy!
  end
end

# Mixin that includes show/list mixins.
module RESTFramework::Mixins::ReadOnlyModelControllerMixin
  include RESTFramework::Mixins::BaseModelControllerMixin

  include RESTFramework::Mixins::ListModelMixin
  include RESTFramework::Mixins::ShowModelMixin

  def self.included(base)
    RESTFramework::BaseModelControllerMixin.included(base)
  end
end

# Mixin that includes all the CRUD mixins.
module RESTFramework::Mixins::ModelControllerMixin
  include RESTFramework::Mixins::BaseModelControllerMixin

  include RESTFramework::Mixins::ListModelMixin
  include RESTFramework::Mixins::ShowModelMixin
  include RESTFramework::Mixins::CreateModelMixin
  include RESTFramework::Mixins::UpdateModelMixin
  include RESTFramework::Mixins::DestroyModelMixin

  def self.included(base)
    RESTFramework::BaseModelControllerMixin.included(base)
  end
end

# Aliases for convenience.
RESTFramework::BaseModelControllerMixin = RESTFramework::Mixins::BaseModelControllerMixin
RESTFramework::ListModelMixin = RESTFramework::Mixins::ListModelMixin
RESTFramework::ShowModelMixin = RESTFramework::Mixins::ShowModelMixin
RESTFramework::CreateModelMixin = RESTFramework::Mixins::CreateModelMixin
RESTFramework::UpdateModelMixin = RESTFramework::Mixins::UpdateModelMixin
RESTFramework::DestroyModelMixin = RESTFramework::Mixins::DestroyModelMixin
RESTFramework::ReadOnlyModelControllerMixin = RESTFramework::Mixins::ReadOnlyModelControllerMixin
RESTFramework::ModelControllerMixin = RESTFramework::Mixins::ModelControllerMixin
