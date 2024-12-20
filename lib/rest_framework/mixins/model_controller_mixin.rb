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

    # Options for what should be included/excluded from default fields.
    exclude_associations: false,
  }
  RRF_BASE_MODEL_INSTANCE_CONFIG = {
    # Attributes for finding records.
    find_by_fields: nil,
    find_by_query_param: "find_by",

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
          input_fields, self.get_model, exclude_associations: self.exclude_associations
        )
      elsif !input_fields
        # Otherwise, if fields is nil, then fallback to columns.
        model = self.get_model
        return model ? RESTFramework::Utils.fields_for(
          model, exclude_associations: self.exclude_associations
        ) : []
      elsif input_fields
        input_fields = input_fields.map(&:to_s)
      end

      return input_fields
    end

    # Get a field's config, including defaults.
    def field_config_for(f)
      f = f.to_sym
      @_field_config_for ||= {}
      return @_field_config_for[f] if @_field_config_for[f]

      config = self.field_config&.dig(f) || {}

      # Default sub-fields if field is an association.
      if ref = self.get_model.reflections[f.to_s]
        if ref.polymorphic?
          columns = {}
        else
          model = ref.klass
          columns = model.columns_hash
        end
        config[:sub_fields] ||= RESTFramework::Utils.sub_fields_for(ref)
        config[:sub_fields] = config[:sub_fields].map(&:to_s)

        # Serialize very basic metadata about sub-fields.
        config[:sub_fields_metadata] = config[:sub_fields].map { |sf|
          v = {}

          if columns[sf]
            v[:kind] = "column"
          end

          next [sf, v]
        }.to_h.compact.presence
      end

      return @_field_config_for[f] = config.compact
    end

    # Get metadata about the resource's fields.
    def fields_metadata
      return @_fields_metadata if @_fields_metadata

      # Get metadata sources.
      model = self.get_model
      fields = self.get_fields.map(&:to_s)
      columns = model.columns_hash
      column_defaults = model.column_defaults
      reflections = model.reflections
      attributes = model._default_attributes
      readonly_attributes = model.readonly_attributes
      exclude_body_fields = self.exclude_body_fields.map(&:to_s)
      rich_text_association_names = model.reflect_on_all_associations(:has_one)
        .collect(&:name)
        .select { |n| n.to_s.start_with?("rich_text_") }
      attachment_reflections = model.attachment_reflections

      return @_fields_metadata = fields.map { |f|
        # Initialize metadata to make the order consistent.
        metadata = {
          type: nil,
          kind: nil,
          label: self.label_for(f),
          primary_key: nil,
          required: nil,
          read_only: nil,
        }

        # Determine `primary_key` based on model.
        if model.primary_key == f
          metadata[:primary_key] = true
        end

        # Determine if the field is a read-only attribute.
        if metadata[:primary_key] || f.in?(readonly_attributes) || f.in?(exclude_body_fields)
          metadata[:read_only] = true
        end

        # Determine `type`, `required`, `label`, and `kind` based on schema.
        if column = columns[f]
          metadata[:kind] = "column"
          metadata[:type] = column.type
          metadata[:required] = true unless column.null
        end

        # Determine `default` based on schema; we use `column_defaults` rather than `columns_hash`
        # because these are casted to the proper type.
        column_default = column_defaults[f]
        unless column_default.nil?
          metadata[:default] = column_default
        end

        # Extract details from the model's attributes hash.
        if attributes.key?(f) && attribute = attributes[f]
          unless metadata.key?(:default)
            default = attribute.value_before_type_cast
            metadata[:default] = default unless default.nil?
          end
          metadata[:kind] ||= "attribute"

          # Get any type information from the attribute.
          if type = attribute.type
            metadata[:type] ||= type.type

            # Get enum variants.
            if type.is_a?(ActiveRecord::Enum::EnumType)
              metadata[:enum_variants] = type.send(:mapping)

              # Custom integration with `translate_enum`.
              translate_method = "translated_#{f.pluralize}"
              if model.respond_to?(translate_method)
                metadata[:enum_translations] = model.send(translate_method)
              end
            end
          end
        end

        # Get association metadata.
        if ref = reflections[f]
          metadata[:kind] = "association"

          # Determine if we render id/ids fields. Unfortunately, `has_one` does not provide this
          # interface.
          if self.permit_id_assignment && id_field = RESTFramework::Utils.get_id_field(f, ref)
            metadata[:id_field] = id_field
          end

          # Determine if we render nested attributes options.
          if self.permit_nested_attributes_assignment && (
            nested_opts = model.nested_attributes_options[f.to_sym].presence
          )
            metadata[:nested_attributes_options] = {field: "#{f}_attributes", **nested_opts}
          end

          begin
            pk = ref.active_record_primary_key
          rescue ActiveRecord::UnknownPrimaryKey
          end
          metadata[:association] = {
            macro: ref.macro,
            collection: ref.collection?,
            class_name: ref.class_name,
            foreign_key: ref.foreign_key,
            primary_key: pk,
            polymorphic: ref.polymorphic?,
            table_name: ref.polymorphic? ? nil : ref.table_name,
            options: ref.options.as_json.presence,
          }.compact
        end

        # Determine if this is an ActionText "rich text".
        if :"rich_text_#{f}".in?(rich_text_association_names)
          metadata[:kind] = "rich_text"
        end

        # Determine if this is an ActiveStorage attachment.
        if ref = attachment_reflections[f]
          metadata[:kind] = "attachment"
          metadata[:attachment] = {
            macro: ref.macro,
          }
        end

        # Determine if this is just a method.
        if !metadata[:kind] && model.method_defined?(f)
          metadata[:kind] = "method"
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
          metadata[:required] = true if kind == :presence

          # Resolve procs (and lambdas), and symbols for certain arguments.
          if options[:in].is_a?(Proc)
            options = options.merge(in: options[:in].call)
          elsif options[:in].is_a?(Symbol)
            options = options.merge(in: model.send(options[:in]))
          end

          metadata[:validators] ||= {}
          metadata[:validators][kind] ||= []
          metadata[:validators][kind] << options
        end

        # Serialize any field config.
        metadata[:config] = self.field_config_for(f).presence

        next [f, metadata.compact]
      }.to_h
    end

    # Get a hash of metadata to be rendered in the `OPTIONS` response.
    def options_metadata
      return super.merge(
        {
          primary_key: self.get_model.primary_key,
          fields: self.fields_metadata,
          callbacks: self._process_action_callbacks.as_json,
        },
      )
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
        (self::RRF_BASE_MODEL_CONFIG.keys + self::RRF_BASE_MODEL_INSTANCE_CONFIG.keys).each { |k|
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
    RRF_BASE_MODEL_INSTANCE_CONFIG.each do |a, default|
      next if base.respond_to?(a)

      base.class_attribute(a, default: default)
    end
  end

  # Get a list of fields for this controller.
  def get_fields
    return self.class.get_fields(input_fields: self.class.fields)
  end

  def options_metadata
    return self.class.options_metadata
  end

  # Get a list of parameters allowed for the current action.
  def get_allowed_parameters
    return @_get_allowed_parameters if defined?(@_get_allowed_parameters)

    @_get_allowed_parameters = self.allowed_parameters
    return @_get_allowed_parameters if @_get_allowed_parameters

    # Assemble strong parameters.
    variations = []
    hash_variations = {}
    reflections = self.class.get_model.reflections
    @_get_allowed_parameters = self.get_fields.map { |f|
      f = f.to_s

      # ActiveStorage Integration: `has_one_attached`.
      if reflections.key?("#{f}_attachment")
        hash_variations[f] = ACTIVESTORAGE_KEYS
        next f
      end

      # ActiveStorage Integration: `has_many_attached`.
      if reflections.key?("#{f}_attachments")
        hash_variations[f] = ACTIVESTORAGE_KEYS
        next nil
      end

      # ActionText Integration.
      if reflections.key?("rich_test_#{f}")
        next f
      end

      # Return field if it's not an association.
      next f unless ref = reflections[f]

      # Add `_id`/`_ids` variations for associations.
      if self.permit_id_assignment && id_field = RESTFramework::Utils.get_id_field(f, ref)
        if id_field.ends_with?("_ids")
          hash_variations[id_field] = []
        else
          variations << id_field
        end
      end

      # Add `_attributes` variations for associations.
      if self.permit_nested_attributes_assignment
        hash_variations["#{f}_attributes"] = (
          self.class.field_config_for(f)[:sub_fields] + ["_destroy"]
        )
      end

      # Associations are not allowed to be submitted in their bare form (if they are submitted that
      # way, they will be translated to either ID assignment or nested attributes assignment).
      next nil
    }.compact
    @_get_allowed_parameters += variations
    @_get_allowed_parameters << hash_variations

    return @_get_allowed_parameters
  end

  def serializer_class
    return super || RESTFramework::NativeSerializer
  end

  def apply_filters(data)
    # TODO: Compatibility; remove in 1.0.
    if filtered_data = self.try(:get_filtered_data, data)
      return filtered_data
    end

    return self.filter_backends&.reduce(data) { |d, filter|
      filter.new(controller: self).filter_data(d)
    } || data
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
        elsif id_field = RESTFramework::Utils.get_id_field(name, ref)
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
    if self.filter_pk_from_request_body && bulk_mode != :update
      body_params.delete(pk)
    end

    # Filter fields in `exclude_body_fields`.
    (self.exclude_body_fields || []).each { |f| body_params.delete(f) }

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
    return @records ||= self.apply_filters(self.get_recordset)
  end

  # Get a single record by primary key or another column, if allowed. The return value is memoized
  # and exposed to the view as the `@record` instance variable.
  def get_record
    return @record if @record

    find_by_key = self.class.get_model.primary_key
    is_pk = true

    # Find by another column if it's permitted.
    if find_by_param = self.find_by_query_param.presence
      if find_by = params[find_by_param].presence
        find_by_fields = self.find_by_fields&.map(&:to_s)

        if !find_by_fields || find_by.in?(find_by_fields)
          is_pk = false unless find_by_key == find_by
          find_by_key = find_by
        end
      end
    end

    # Get the recordset, filtering if configured.
    collection = if self.filter_recordset_before_find
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
    if self.create_from_recordset
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
    s = RESTFramework::Utils.wrap_ams(self.serializer_class)
    serialized_records = records.map do |record|
      s.new(record, controller: self).serialize.merge!({errors: record.errors.presence}.compact)
    end

    return serialized_records
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
    if self.paginator_class
      # If there is no `max_page_size`, `page_size_query_param` is not `nil`, and the page size is
      # set to "0", then skip pagination.
      unless !self.max_page_size &&
          self.page_size_query_param &&
          params[self.page_size_query_param] == "0"
        paginator = self.paginator_class.new(data: records, controller: self)
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
