require_relative "base"
require_relative "../filters"

# This module provides the core functionality for controllers based on models.
module RESTFramework::BaseModelControllerMixin
  include RESTFramework::BaseControllerMixin

  module ClassMethods
    IGNORE_VALIDATORS_WITH_KEYS = [:if, :unless]

    # Get the model for this controller.
    def get_model(from_get_recordset: false)
      return @model if @model
      return (@model = self.model) if self.model

      # Delegate to the recordset's model, if it's defined.
      unless from_get_recordset  # Prevent infinite recursion.
        if (recordset = self.new.get_recordset)
          return @model = recordset.klass
        end
      end

      # Try to determine model from controller name.
      begin
        return @model = self.name.demodulize.match(/(.*)Controller/)[1].singularize.constantize
      rescue NameError
      end

      return nil
    end

    # Get metadata about the resource's fields.
    def get_fields_metadata
      # Get metadata sources.
      model = self.get_model
      fields = self.fields&.map(&:to_s) || model&.column_names || []
      columns = model&.columns_hash
      column_defaults = model&.column_defaults
      attributes = model&._default_attributes

      return fields.map { |f|
        # Initialize metadata to make the order consistent.
        metadata = {type: nil, kind: nil, label: nil, required: nil, read_only: nil}

        # Determine `type`, `required`, `label`, and `kind` based on schema.
        if column = columns[f]
          metadata[:type] = column.type
          metadata[:required] = true unless column.null
          metadata[:label] = column.human_name.instance_eval { |n| n == "Id" ? "ID" : n }
          metadata[:kind] = "column"
        end

        # Determine `default` based on schema; we use `column_defaults` rather than `columns_hash`
        # because these are casted to the proper type.
        column_default = column_defaults[f]
        unless column_default.nil?
          metadata[:default] = column_default
        end

        # Determine `default` and `kind` based on attribute only if not determined by the DB.
        if attributes.key?(f) && attribute = attributes[f]
          unless metadata.key?(:default)
            default = attribute.value_before_type_cast
            metadata[:default] = default unless default.nil?
          end

          unless metadata[:kind]
            metadata[:kind] = "attribute"
          end
        end

        # Determine if `kind` is a association or method if not determined already.
        unless metadata[:kind]
          if association = model.reflections[f]
            metadata[:kind] = "association.#{association.macro}"
          elsif model.method_defined?(f)
            metadata[:kind] = "method"
          end
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

          metadata[:validators] ||= {}
          metadata[:validators][kind] ||= []
          metadata[:validators][kind] << options
        end

        next [f, metadata.compact]
      }.to_h
    end

    # Get a hash of metadata to be rendered in the `OPTIONS` response. Cache the result.
    def get_options_metadata
      return @_model_options_metadata ||= super.merge(
        {
          fields: self.get_fields_metadata,
        },
      )
    end
  end

  def self.included(base)
    if base.is_a?(Class)
      RESTFramework::BaseControllerMixin.included(base)
      base.extend(ClassMethods)

      # Add class attributes (with defaults) unless they already exist.
      {
        # Core attributes related to models.
        model: nil,
        recordset: nil,

        # Attributes for configuring record fields.
        fields: nil,
        action_fields: nil,
        metadata_fields: nil,

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

        # Attributes for default model filtering, ordering, and searching.
        filterset_fields: nil,
        ordering_fields: nil,
        ordering_query_param: "ordering",
        ordering_no_reorder: false,
        search_fields: nil,
        search_query_param: "search",
        search_ilike: false,

        # Other misc attributes.
        create_from_recordset: true,  # Option for `recordset.create` vs `Model.create` behavior.
        filter_recordset_before_find: true,  # Option to control if filtering is done before find.
      }.each do |a, default|
        next if base.respond_to?(a)

        base.class_attribute(a)

        # Set default manually so we can still support Rails 4. Maybe later we can use the default
        # parameter on `class_attribute`.
        base.send(:"#{a}=", default)
      end
    end
  end

  def _get_specific_action_config(action_config_key, generic_config_key)
    action_config = self.class.send(action_config_key)&.with_indifferent_access || {}
    action = self.action_name&.to_sym

    # Index action should use :list serializer if :index is not provided.
    action = :list if action == :index && !action_config.key?(:index)

    return (action_config[action] if action) || self.class.send(generic_config_key)
  end

  # Get a list of fields for the current action. Returning `nil` indicates that anything should be
  # accepted unless `fallback` is true, in which case we should fallback to this controller's model
  # columns, or en empty array.
  def get_fields(fallback: false)
    fields = _get_specific_action_config(:action_fields, :fields)

    if fallback
      fields ||= self.class.get_model&.column_names || []
    end

    return fields
  end

  # Get a list of find_by fields for the current action. Do not fallback to columns in case the user
  # wants to find by virtual columns.
  def get_find_by_fields
    return self.class.find_by_fields || self.get_fields
  end

  # Get a list of parameters allowed for the current action. By default we do not fallback to
  # columns so arbitrary fields can be submitted if no fields are defined.
  def get_allowed_parameters
    return _get_specific_action_config(
      :allowed_action_parameters,
      :allowed_parameters,
    ) || self.fields
  end

  # Helper to get the configured serializer class, or `NativeSerializer` as a default.
  def get_serializer_class
    return super || RESTFramework::NativeSerializer
  end

  # Helper to get filtering backends, defaulting to using `ModelFilter` and `ModelOrderingFilter`.
  def get_filter_backends
    return self.class.filter_backends || [
      RESTFramework::ModelFilter, RESTFramework::ModelOrderingFilter
    ]
  end

  # Filter the request body for keys in current action's allowed_parameters/fields config.
  def get_body_params
    # Filter the request body and map to strings. Return all params if we cannot resolve a list of
    # allowed parameters or fields.
    allowed_params = self.get_allowed_parameters&.map(&:to_s)
    body_params = if allowed_params
      request.request_parameters.select { |p| allowed_params.include?(p) }
    else
      request.request_parameters
    end

    # Add query params in place of missing body params, if configured.
    if self.class.accept_generic_params_as_body_params && allowed_params
      (allowed_params - body_params.keys).each do |k|
        if value = params[k].presence
          body_params[k] = value
        end
      end
    end

    # Filter primary key if configured.
    if self.class.filter_pk_from_request_body
      body_params.delete(self.class.get_model&.primary_key)
    end

    # Filter fields in exclude_body_fields.
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
    if (model = self.class.get_model(from_get_recordset: true))
      return @recordset = model.all
    end

    return @recordset = nil
  end

  # Helper to get the records this controller has access to *after* any filtering is applied.
  def get_records
    return @records if instance_variable_defined?(:@records)

    return @records = self.get_filtered_data(self.get_recordset)
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
    return @record = recordset.find_by!(find_by_key => params[:id])
  end
end

# Mixin for listing records.
module RESTFramework::ListModelMixin
  def index
    return api_response(self.get_index_records)
  end

  # Helper to get records with both filtering and pagination applied.
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

  # Helper to perform the `create!` call and return the created record.
  def create!
    if self.get_recordset.respond_to?(:create!) && self.create_from_recordset
      # Create with any properties inherited from the recordset. We exclude any `select` clauses in
      # case model callbacks need to call `count` on this collection, which typically raises a SQL
      # `SyntaxError`.
      return self.get_recordset.except(:select).create!(self.get_create_params)
    else
      # Otherwise, perform a "bare" create.
      return self.class.get_model.create!(self.get_create_params)
    end
  end
end

# Mixin for updating records.
module RESTFramework::UpdateModelMixin
  def update
    return api_response(self.update!)
  end

  # Helper to perform the `update!` call and return the updated record.
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

  # Helper to perform the `destroy!` call and return the destroyed (and frozen) record.
  def destroy!
    return self.get_record.destroy!
  end
end

# Mixin that includes show/list mixins.
module RESTFramework::ReadOnlyModelControllerMixin
  include RESTFramework::BaseModelControllerMixin

  def self.included(base)
    if base.is_a?(Class)
      RESTFramework::BaseModelControllerMixin.included(base)
    end
  end

  include RESTFramework::ListModelMixin
  include RESTFramework::ShowModelMixin
end

# Mixin that includes all the CRUD mixins.
module RESTFramework::ModelControllerMixin
  include RESTFramework::BaseModelControllerMixin

  def self.included(base)
    if base.is_a?(Class)
      RESTFramework::BaseModelControllerMixin.included(base)
    end
  end

  include RESTFramework::ListModelMixin
  include RESTFramework::ShowModelMixin
  include RESTFramework::CreateModelMixin
  include RESTFramework::UpdateModelMixin
  include RESTFramework::DestroyModelMixin
end
