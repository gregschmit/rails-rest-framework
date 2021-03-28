require_relative 'base'
require_relative '../filters'


# This module provides the core functionality for controllers based on models.
module RESTFramework::BaseModelControllerMixin
  include RESTFramework::BaseControllerMixin

  def self.included(base)
    if base.is_a? Class
      RESTFramework::BaseControllerMixin.included(base)

      # Add class attributes (with defaults) unless they already exist.
      {
        # Core attributes related to models.
        model: nil,
        recordset: nil,

        # Attributes for configuring record fields.
        fields: nil,
        action_fields: nil,

        # Attributes for create/update parameters.
        allowed_parameters: nil,
        allowed_action_parameters: nil,

        # Attributes for the default native serializer.
        native_serializer_config: nil,
        native_serializer_singular_config: nil,
        native_serializer_plural_config: nil,

        # Attributes for default model filtering (and ordering).
        filterset_fields: nil,
        ordering_fields: nil,
        ordering_query_param: 'ordering',

        # Other misc attributes.
        disable_creation_from_recordset: false,  # Option to disable `recordset.create` behavior.
      }.each do |a, default|
        unless base.respond_to?(a)
          base.class_attribute(a)

          # Set default manually so we can still support Rails 4. Maybe later we can use the default
          # parameter on `class_attribute`.
          base.send(:"#{a}=", default)
        end
      end
    end
  end

  protected

  def _get_specific_action_config(action_config_key, generic_config_key)
    action_config = self.class.send(action_config_key) || {}
    action = self.action_name&.to_sym

    # Index action should use :list serializer if :index is not provided.
    action = :list if action == :index && !action_config.key?(:index)

    return (action_config[action] if action) || self.class.send(generic_config_key)
  end

  # Get a list of parameters allowed for the current action.
  def get_allowed_parameters
    return _get_specific_action_config(:allowed_action_parameters, :allowed_parameters)&.map(&:to_s)
  end

  # Get a list of fields for the current action.
  def get_fields
    return (
      _get_specific_action_config(:action_fields, :fields)&.map(&:to_s) ||
      self.get_model&.column_names ||
      []
    )
  end

  # Helper to get the configured serializer class, or `NativeSerializer` as a default.
  # @return [RESTFramework::BaseSerializer]
  def get_serializer_class
    return self.class.serializer_class || RESTFramework::NativeSerializer
  end

  # Get the list of filtering backends to use.
  # @return [RESTFramework::BaseFilter]
  def get_filter_backends
    return self.class.filter_backends || [
      RESTFramework::ModelFilter, RESTFramework::ModelOrderingFilter
    ]
  end

  # Filter the request body for keys in current action's allowed_parameters/fields config.
  def get_body_params
    return @_get_body_params ||= begin
      fields = self.get_allowed_parameters || self.get_fields

      # Filter the request body.
      body_params = request.request_parameters.select { |p|
        fields.include?(p)
      }

      # Add query params in place of missing body params, if configured.
      if self.class.accept_generic_params_as_body_params
        (fields - body_params.keys).each do |k|
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
      (self.class.exclude_body_fields || []).each do |f|
        body_params.delete(f.to_s)
      end

      body_params
    end
  end
  alias :get_create_params :get_body_params
  alias :get_update_params :get_body_params

  # Get a record by the primary key from the (non-filtered) recordset.
  def get_record
    if pk = params[self.get_model.primary_key]
      return self.get_recordset.find(pk)
    end
    return nil
  end

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
      return (@model = self.class.name.demodulize.match(/(.*)Controller/)[1].singularize.constantize)
    rescue NameError
    end

    return nil
  end

  # Get the set of records this controller has access to.
  def get_recordset
    return @recordset if instance_variable_defined?(:@recordset) && @recordset
    return (@recordset = self.class.recordset) if self.class.recordset

    # If there is a model, return that model's default scope (all records by default).
    if (model = self.get_model(from_get_recordset: true))
      return @recordset = model.all
    end

    return nil
  end
end


# Mixin for listing records.
module RESTFramework::ListModelMixin
  def index
    @records = self.get_filtered_data(self.get_recordset)

    # Handle pagination, if enabled.
    if self.class.paginator_class
      paginator = self.class.paginator_class.new(data: @records, controller: self)
      page = paginator.get_page
      serialized_page = self.get_serializer_class.new(object: page, controller: self).serialize
      data = paginator.get_paginated_response(serialized_page)
    else
      data = self.get_serializer_class.new(object: @records, controller: self).serialize
    end

    return api_response(data)
  end
end


# Mixin for showing records.
module RESTFramework::ShowModelMixin
  def show
    @record = self.get_record
    serialized_record = self.get_serializer_class.new(object: @record, controller: self).serialize
    return api_response(serialized_record)
  end
end


# Mixin for creating records.
module RESTFramework::CreateModelMixin
  def create
    if self.get_recordset.respond_to?(:create!) && !self.disable_creation_from_recordset
      # Create with any properties inherited from the recordset (like associations).
      @record = self.get_recordset.create!(self.get_create_params)
    else
      # Otherwise, perform a "bare" create.
      @record = self.get_model.create!(self.get_create_params)
    end
    serialized_record = self.get_serializer_class.new(object: @record, controller: self).serialize
    return api_response(serialized_record)
  end
end


# Mixin for updating records.
module RESTFramework::UpdateModelMixin
  def update
    @record = self.get_record
    @record.update!(self.get_update_params)
    serialized_record = self.get_serializer_class.new(object: @record, controller: self).serialize
    return api_response(serialized_record)
  end
end


# Mixin for destroying records.
module RESTFramework::DestroyModelMixin
  def destroy
    @record = self.get_record
    @record.destroy!
    api_response('')
  end
end


# Mixin that includes show/list mixins.
module RESTFramework::ReadOnlyModelControllerMixin
  include RESTFramework::BaseModelControllerMixin

  def self.included(base)
    if base.is_a? Class
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
    if base.is_a? Class
      RESTFramework::BaseModelControllerMixin.included(base)
    end
  end

  include RESTFramework::ListModelMixin
  include RESTFramework::ShowModelMixin
  include RESTFramework::CreateModelMixin
  include RESTFramework::UpdateModelMixin
  include RESTFramework::DestroyModelMixin
end
