require_relative "base"
require_relative "../filters"

# This module provides the core functionality for controllers based on models.
module RESTFramework::BaseModelControllerMixin
  include RESTFramework::BaseControllerMixin

  RRF_BASE_MODEL_CONTROLLER_CONFIG = {
    # Core attributes related to models.
    model: nil,
    recordset: nil,

    # Attributes for configuring record fields.
    fields: nil,
    field_config: nil,
    action_fields: nil,

    # Options for what should be included/excluded from default fields.
    exclude_associations: false,
    include_active_storage: false,
    include_action_text: false,

    # Attributes for finding records.
    find_by_fields: nil,
    find_by_query_param: "find_by",

    # Attributes for create/update parameters.
    allowed_parameters: nil,
    allowed_action_parameters: nil,

    # Attributes for the default native serializer.
    native_serializer_config: nil,
    native_serializer_singular_config: nil,
    native_serializer_plural_config: nil,
    native_serializer_only_query_param: "only",
    native_serializer_except_query_param: "except",
    native_serializer_associations_limit: nil,
    native_serializer_associations_limit_query_param: "associations_limit",
    native_serializer_include_associations_count: false,

    # Attributes for default model filtering, ordering, and searching.
    filterset_fields: nil,
    ordering_fields: nil,
    ordering_query_param: "ordering",
    ordering_no_reorder: false,
    search_fields: nil,
    search_query_param: "search",
    search_ilike: false,

    # Options for association assignment.
    permit_id_assignment: true,
    permit_nested_attributes_assignment: true,
    allow_all_nested_attributes: false,

    # Option for `recordset.create` vs `Model.create` behavior.
    create_from_recordset: true,

    # Control if filtering is done before find.
    filter_recordset_before_find: true,

    # Control if bulk operations are done in a transaction and rolled back on error, or if all bulk
    # operations are attempted and errors simply returned in the response.
    bulk_transactional: false,

    # Control if bulk operations should be done in "batch" mode, using efficient queries, but also
    # skipping model validations/callbacks.
    bulk_batch_mode: false,
  }

  module ClassMethods
    IGNORE_VALIDATORS_WITH_KEYS = [:if, :unless].freeze

    # Get the model for this controller.
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

    # Override `get_label` to include ActiveRecord i18n-translated column names.
    def get_label(s)
      return self.get_model.human_attribute_name(s, default: super)
    end

    # Get the available fields. Returning `nil` indicates that anything should be accepted. If
    # `fallback` is true, then we should fallback to this controller's model columns, or an empty
    # array. This should always return an array of strings, no symbols, and possibly `nil` (only if
    # `fallback` is false).
    def get_fields(input_fields: nil, fallback: true)
      input_fields ||= self.fields if fallback

      # If fields is a hash, then parse it.
      if input_fields.is_a?(Hash)
        return RESTFramework::Utils.parse_fields_hash(
          input_fields, self.get_model, exclude_associations: self.exclude_associations
        )
      elsif !input_fields && fallback
        # Otherwise, if fields is nil and fallback is true, then fallback to columns.
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
    def get_field_config(f)
      f = f.to_sym
      @_get_field_config ||= {}
      return @_get_field_config[f] if @_get_field_config[f]

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

        # Serialize very basic metadata about sub-fields.
        config[:sub_fields_metadata] = config[:sub_fields].map { |sf|
          v = {}

          if columns[sf]
            v[:kind] = "column"
          end

          next [sf, v]
        }.to_h.compact.presence
      end

      return @_get_field_config[f] = config.compact
    end

    # Get metadata about the resource's fields.
    def get_fields_metadata
      # Get metadata sources.
      model = self.get_model
      fields = self.get_fields.map(&:to_s)
      columns = model.columns_hash
      column_defaults = model.column_defaults
      reflections = model.reflections
      attributes = model._default_attributes

      return fields.map { |f|
        # Initialize metadata to make the order consistent.
        metadata = {
          type: nil,
          kind: nil,
          label: self.get_label(f),
          primary_key: nil,
          required: nil,
          read_only: nil,
        }

        # Determine `primary_key` based on model.
        if model.primary_key == f
          metadata[:primary_key] = true
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

          # Determine if we render id/ids fields.
          if self.permit_id_assignment
            if ref.collection?
              metadata[:id_field] = "#{f.singularize}_ids"
            elsif ref.belongs_to?
              metadata[:id_field] = "#{f}_id"
            end
          end

          # Determine if we render nested attributes options.
          if self.permit_nested_attributes_assignment
            if nested_opts = model.nested_attributes_options[f.to_sym].presence
              nested_opts[:field] = "#{f}_attributes"
              metadata[:nested_attributes_options] = nested_opts
            end
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
            table_name: ref.table_name,
            options: ref.options.as_json.presence,
          }.compact
        end

        # Determine if this is just a method.
        if model.method_defined?(f)
          metadata[:kind] ||= "method"
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
        metadata[:config] = self.get_field_config(f).presence

        next [f, metadata.compact]
      }.to_h
    end

    # Get a hash of metadata to be rendered in the `OPTIONS` response.
    def get_options_metadata
      return super.merge(
        {
          primary_key: self.get_model.primary_key,
          fields: self.get_fields_metadata,
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
        self::RRF_BASE_MODEL_CONTROLLER_CONFIG.keys.each { |k|
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
    RRF_BASE_MODEL_CONTROLLER_CONFIG.each do |a, default|
      next if base.respond_to?(a)

      base.class_attribute(a)

      # Set default manually so we can still support Rails 4. Maybe later we can use the default
      # parameter on `class_attribute`.
      base.send(:"#{a}=", default)
    end
  end

  def _get_specific_action_config(action_config_key, generic_config_key)
    action_config = self.class.send(action_config_key)&.with_indifferent_access || {}
    action = self.action_name&.to_sym

    # Index action should use :list serializer if :index is not provided.
    action = :list if action == :index && !action_config.key?(:index)

    return (action_config[action] if action) || self.class.send(generic_config_key)
  end

  # Get a list of fields, taking into account the current action.
  def get_fields(fallback: false)
    fields = self._get_specific_action_config(:action_fields, :fields)
    return self.class.get_fields(input_fields: fields, fallback: fallback)
  end

  # Pass fields to get dynamic metadata based on which fields are available.
  def get_options_metadata
    return self.class.get_options_metadata
  end

  # Get a list of find_by fields for the current action. Do not fallback to columns in case the user
  # wants to find by virtual columns.
  def get_find_by_fields
    return self.class.find_by_fields || self.get_fields
  end

  # Get a list of parameters allowed for the current action. By default we do not fallback to
  # columns so arbitrary fields can be submitted if no fields are defined.
  def get_allowed_parameters
    return @_get_allowed_parameters if defined?(@_get_allowed_parameters)

    @_get_allowed_parameters = self._get_specific_action_config(
      :allowed_action_parameters,
      :allowed_parameters,
    )
    return @_get_allowed_parameters if @_get_allowed_parameters
    return @_get_allowed_parameters = nil unless fields = self.get_fields

    # For fields, automatically add `_id`/`_ids` and `_attributes` variations for associations.
    id_variations = []
    variations = {}
    @_get_allowed_parameters = fields.map { |f|
      f = f.to_s
      next f unless ref = self.class.get_model.reflections[f]

      if self.class.permit_id_assignment
        if ref.collection?
          variations["#{f.singularize}_ids"] = []
        elsif ref.belongs_to?
          id_variations << "#{f}_id"
        end
      end

      if self.class.permit_nested_attributes_assignment
        if self.class.allow_all_nested_attributes
          variations["#{f}_attributes"] = {}
        else
          variations["#{f}_attributes"] = self.class.get_field_config(f)[:sub_fields]
        end
      end

      next f
    }.flatten
    @_get_allowed_parameters += id_variations
    @_get_allowed_parameters << variations
    return @_get_allowed_parameters
  end

  # Get the configured serializer class, or `NativeSerializer` as a default.
  def get_serializer_class
    return super || RESTFramework::NativeSerializer
  end

  # Get filtering backends, defaulting to using `ModelFilter`, `ModelOrderingFilter`, and
  # `ModelSearchFilter`.
  def get_filter_backends
    return self.class.filter_backends || [
      RESTFramework::ModelFilter,
      RESTFramework::ModelOrderingFilter,
      RESTFramework::ModelSearchFilter,
    ]
  end

  # Use strong parameters to filter the request body using the configured allowed parameters.
  def get_body_params(data: nil)
    data ||= request.request_parameters

    # Filter the request body and map to strings. Return all params if we cannot resolve a list of
    # allowed parameters or fields.
    body_params = if allowed_parameters = self.get_allowed_parameters
      data = ActionController::Parameters.new(data)
      data.permit(*allowed_parameters)
    else
      data
    end

    # Filter primary key if configured.
    if self.class.filter_pk_from_request_body
      body_params.delete(self.class.get_model&.primary_key)
    end

    # Filter fields in `exclude_body_fields`.
    (self.class.exclude_body_fields || []).each { |f| body_params.delete(f) }

    return body_params
  end
  alias_method :get_create_params, :get_body_params
  alias_method :get_update_params, :get_body_params

  # Get the set of records this controller has access to. The return value is cached and exposed to
  # the view as the `@recordset` instance variable.
  def get_recordset
    return @recordset if instance_variable_defined?(:@recordset)
    return (@recordset = self.class.recordset) if self.class.recordset

    # If there is a model, return that model's default scope (all records by default).
    if (model = self.class.get_model)
      return @recordset = model.all
    end

    return @recordset = nil
  end

  # Get the recordset but with any associations included to avoid N+1 queries.
  def get_recordset_with_includes
    reflections = self.class.get_model.reflections.keys
    associations = self.get_fields(fallback: true).select { |f| f.in?(reflections) }

    if associations.any?
      return self.get_recordset.includes(associations)
    end

    return self.get_recordset
  end

  # Get the records this controller has access to *after* any filtering is applied.
  def get_records
    return @records if instance_variable_defined?(:@records)

    return @records = self.get_filtered_data(self.get_recordset_with_includes)
  end

  # Get a single record by primary key or another column, if allowed. The return value is cached and
  # exposed to the view as the `@record` instance variable.
  def get_record
    # Cache the result.
    return @record if instance_variable_defined?(:@record)

    recordset = self.get_recordset
    find_by_key = self.class.get_model.primary_key

    # Find by another column if it's permitted.
    if find_by_param = self.class.find_by_query_param.presence
      if find_by = params[find_by_param].presence
        find_by_fields = self.get_find_by_fields&.map(&:to_s)

        if !find_by_fields || find_by.in?(find_by_fields)
          find_by_key = find_by
        end
      end
    end

    # Filter recordset, if configured.
    if self.filter_recordset_before_find
      recordset = self.get_records
    end

    # Return the record. Route key is always `:id` by Rails convention.
    return @record = recordset.find_by!(find_by_key => request.path_parameters[:id])
  end

  # Create a transaction around the passed block, if configured. This is used primarily for bulk
  # actions, but we include it here so it's always available.
  def self._rrf_bulk_transaction(&block)
    if self.bulk_transactional
      ActiveRecord::Base.transaction(&block)
    else
      yield
    end
  end
end

# Mixin for listing records.
module RESTFramework::ListModelMixin
  def index
    return api_response(self.get_index_records)
  end

  # Get records with both filtering and pagination applied.
  def get_index_records
    records = self.get_records

    # Handle pagination, if enabled.
    if self.class.paginator_class
      # If there is no `max_page_size`, `page_size_query_param` is not `nil`, and the page size is
      # set to "0", then skip pagination.
      unless !self.class.max_page_size &&
          self.class.page_size_query_param &&
          params[self.class.page_size_query_param] == "0"
        paginator = self.class.paginator_class.new(data: records, controller: self)
        page = paginator.get_page
        serialized_page = self.serialize(page)
        return paginator.get_paginated_response(serialized_page)
      end
    end

    return records
  end
end

# Mixin for showing records.
module RESTFramework::ShowModelMixin
  def show
    return api_response(self.get_record)
  end
end

# Mixin for creating records.
module RESTFramework::CreateModelMixin
  def create
    return api_response(self.create!, status: :created)
  end

  # Perform the `create!` call and return the created record.
  def create!
    create_from = if self.create_from_recordset && self.get_recordset.respond_to?(:create!)
      # Create with any properties inherited from the recordset. We exclude any `select` clauses in
      # case model callbacks need to call `count` on this collection, which typically raises a SQL
      # `SyntaxError`.
      self.get_recordset.except(:select)
    else
      # Otherwise, perform a "bare" create.
      self.class.get_model
    end

    return create_from.create!(self.get_create_params)
  end
end

# Mixin for updating records.
module RESTFramework::UpdateModelMixin
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
module RESTFramework::DestroyModelMixin
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
module RESTFramework::ReadOnlyModelControllerMixin
  include RESTFramework::BaseModelControllerMixin

  include RESTFramework::ListModelMixin
  include RESTFramework::ShowModelMixin

  def self.included(base)
    RESTFramework::BaseModelControllerMixin.included(base)
  end
end

# Mixin that includes all the CRUD mixins.
module RESTFramework::ModelControllerMixin
  include RESTFramework::BaseModelControllerMixin

  include RESTFramework::ListModelMixin
  include RESTFramework::ShowModelMixin
  include RESTFramework::CreateModelMixin
  include RESTFramework::UpdateModelMixin
  include RESTFramework::DestroyModelMixin

  def self.included(base)
    RESTFramework::BaseModelControllerMixin.included(base)
  end
end
