require_relative "base"
require_relative "../filters"

# This module provides the core functionality for controllers based on models.
module RESTFramework::BaseModelControllerMixin
  include RESTFramework::BaseControllerMixin

  def self.included(base)
    if base.is_a?(Class)
      RESTFramework::BaseControllerMixin.included(base)

      # Add class attributes (with defaults) unless they already exist.
      {
        # Core attributes related to models.
        model: nil,
        recordset: nil,

        # Attributes for configuring record fields.
        fields: nil,
        action_fields: nil,

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

        # Attributes for default model filtering (and ordering).
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
      fields ||= self.get_model&.column_names || []
    end

    return fields
  end

  # Get a list of find_by fields for the current action.
  def get_find_by_fields
    return self.class.find_by_fields || self.get_fields
  end

  # Get a list of find_by fields for the current action. Default to the model column names.
  def get_filterset_fields
    return self.class.filterset_fields || self.get_fields(fallback: true)
  end

  # Get a list of ordering fields for the current action.
  def get_ordering_fields
    return self.class.ordering_fields || self.get_fields
  end

  # Get a list of search fields for the current action. Default to the model column names.
  def get_search_fields
    return self.class.search_fields || self.get_fields(fallback: true)
  end

  # Get a list of parameters allowed for the current action.
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
    return @_get_body_params ||= begin
      # Filter the request body and map to strings. Return all params if we cannot resolve a list of
      # allowed parameters or fields.
      body_params = if allowed_params = self.get_allowed_parameters&.map(&:to_s)
        request.request_parameters.select { |p| allowed_params.include?(p) }
      else
        request.request_parameters
      end

      # Add query params in place of missing body params, if configured. If fields are not defined,
      # fallback to using columns for this particular feature.
      if self.class.accept_generic_params_as_body_params
        (self.get_fields(fallback: true) - body_params.keys).each do |k|
          if (value = params[k])
            body_params[k] = value
          end
        end
      end

      # Filter primary key if configured.
      if self.class.filter_pk_from_request_body
        body_params.delete(self.get_model&.primary_key)
      end

      # Filter fields in exclude_body_fields.
      (self.class.exclude_body_fields || []).each { |f| body_params.delete(f) }

      body_params
    end
  end
  alias_method :get_create_params, :get_body_params
  alias_method :get_update_params, :get_body_params

  # Get the model for this controller.
  def get_model(from_get_recordset: false)
    return @model if instance_variable_defined?(:@model) && @model
    return (@model = self.class.model) if self.class.model

    # Delegate to the recordset's model, if it's defined.
    unless from_get_recordset  # prevent infinite recursion
      if (recordset = self.get_recordset)
        return @model = recordset.klass
      end
    end

    # Try to determine model from controller name.
    begin
      return @model = self.class.name.demodulize.match(/(.*)Controller/)[1].singularize.constantize
    rescue NameError
    end

    return nil
  end

  # Get the set of records this controller has access to. The return value is cached and exposed to
  # the view as the `@recordset` instance variable.
  def get_recordset
    return @recordset if instance_variable_defined?(:@recordset)
    return (@recordset = self.class.recordset) if self.class.recordset

    # If there is a model, return that model's default scope (all records by default).
    if (model = self.get_model(from_get_recordset: true))
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
    find_by_key = self.get_model.primary_key

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
    api_response(self.get_index_records)
  end

  # Helper to get records with both filtering and pagination applied.
  def get_index_records
    records = self.get_records

    # Handle pagination, if enabled.
    if self.class.paginator_class
      paginator = self.class.paginator_class.new(data: records, controller: self)
      page = paginator.get_page
      serialized_page = self.serialize(page)
      return paginator.get_paginated_response(serialized_page)
    end

    return records
  end
end

# Mixin for showing records.
module RESTFramework::ShowModelMixin
  def show
    api_response(self.get_record)
  end
end

# Mixin for creating records.
module RESTFramework::CreateModelMixin
  def create
    api_response(self.create!)
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
      return self.get_model.create!(self.get_create_params)
    end
  end
end

# Mixin for updating records.
module RESTFramework::UpdateModelMixin
  def update
    api_response(self.update!)
  end

  # Helper to perform the `update!` call and return the updated record.
  def update!
    return self.get_record.update!(self.get_update_params)
  end
end

# Mixin for destroying records.
module RESTFramework::DestroyModelMixin
  def destroy
    self.destroy!
    api_response("")
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
