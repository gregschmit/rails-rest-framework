require_relative 'base'
require_relative '../serializers'

module RESTFramework

  module BaseModelControllerMixin
    include BaseControllerMixin
    def self.included(base)
      if base.is_a? Class
        BaseControllerMixin.included(base)
        base.class_attribute(*[
          :model,
          :recordset,
          :fields,
          :action_fields,
          :native_serializer_config,
          :native_serializer_action_config,
          :filterset_fields,
          :allowed_parameters,
          :allowed_action_parameters,
          :serializer_class,
          :extra_member_actions,
        ])
        base.alias_method(:extra_collection_actions=, :extra_actions=)
      end
    end

    protected

    def get_serializer_class
      return self.class.serializer_class || NativeModelSerializer
    end

    # Get a list of fields for the current action.
    def get_fields
      action_fields = self.class.action_fields || {}
      action = self.action_name.to_sym

      # index action should use :list fields if :index is not provided
      action = :list if action == :index && !action_fields.key?(:index)

      return (action_fields[action] if action) || self.class.fields || []
    end

    # Get a native serializer config for the current action.
    def get_native_serializer_config
      action_serializer_config = self.class.native_serializer_action_config || {}
      action = self.action_name.to_sym

      # index action should use :list serializer config if :index is not provided
      action = :list if action == :index && !action_serializer_config.key?(:index)

      return (action_serializer_config[action] if action) || self.class.native_serializer_config
    end

    # Get a list of parameters allowed for the current action.
    def get_allowed_parameters
      allowed_action_parameters = self.class.allowed_action_parameters || {}
      action = self.action_name.to_sym

      # index action should use :list allowed parameters if :index is not provided
      action = :list if action == :index && !allowed_action_parameters.key?(:index)

      return (allowed_action_parameters[action] if action) || self.class.allowed_parameters
    end

    # Filter the request body for keys in current action's allowed_parameters/fields config.
    def _get_parameter_values_from_request_body
      fields = self.get_allowed_parameters || self.get_fields
      return @_get_field_values_from_request_body ||= (request.request_parameters.select { |p|
        fields.include?(p.to_sym) || fields.include?(p.to_s)
      })
    end
    alias :get_create_params :_get_parameter_values_from_request_body
    alias :get_update_params :_get_parameter_values_from_request_body

    # Filter params for keys allowed by the current action's filterset_fields/fields config.
    def _get_filterset_values_from_params
      fields = self.filterset_fields || self.get_fields
      return @_get_field_values_from_params ||= request.query_parameters.select { |p|
        fields.include?(p.to_sym) || fields.include?(p.to_s)
      }
    end
    alias :get_lookup_params :_get_filterset_values_from_params
    alias :get_filter_params :_get_filterset_values_from_params

    # Get the recordset, filtered by the filter params.
    def get_filtered_recordset
      filter_params = self.get_filter_params
      unless filter_params.blank?
        return self.get_recordset.where(**self.get_filter_params.to_hash.symbolize_keys)
      end
      return self.get_recordset
    end

    # Get a record by `id` or return a single record if recordset is filtered down to a single
    # record.
    def get_record
      records = self.get_filtered_recordset
      if params['id']  # direct lookup
        return records.find(params['id'])
      elsif records.length == 1
        return records[0]
      end
      return nil
    end

    # Internal interface for get_model, protecting against infinite recursion with get_recordset.
    def _get_model(from_internal_get_recordset: false)
      return @model if instance_variable_defined?(:@model) && @model
      return self.class.model if self.class.model
      unless from_internal_get_recordset  # prevent infinite recursion
        recordset = self._get_recordset(from_internal_get_model: true)
        return (@model = recordset.klass) if recordset
      end
      begin
        return (@model = self.class.name.demodulize.match(/(.*)Controller/)[1].singularize.constantize)
      rescue NameError
      end
      return nil
    end

    # Internal interface for get_recordset, protecting against infinite recursion with get_model.
    def _get_recordset(from_internal_get_model: false)
      return @recordset if instance_variable_defined?(:@recordset) && @recordset
      return self.class.recordset if self.class.recordset
      unless from_internal_get_model  # prevent infinite recursion
        model = self._get_model(from_internal_get_recordset: true)
        return (@recordset = model.all) if model
      end
      return nil
    end

    # Get the model for this controller.
    def get_model
      return _get_model
    end

    # Get the set of records this controller has access to.
    def get_recordset
      return _get_recordset
    end
  end

  module ListModelMixin
    # TODO: pagination classes like Django
    def index
      @records = self.get_filtered_recordset
      @serialized_records = self.get_serializer_class.new(
        object: @records, controller: self
      ).serialize
      return api_response(@serialized_records)
    end
  end

  module ShowModelMixin
    def show
      @record = self.get_record
      @serialized_record = self.get_serializer_class.new(
        object: @record, controller: self
      ).serialize
      return api_response(@serialized_record)
    end
  end

  module CreateModelMixin
    def create
      @record = self.get_model.create!(self.get_create_params)
      @serialized_record = self.get_serializer_class.new(
        object: @record, controller: self
      ).serialize
      return api_response(@serialized_record)
    end
  end

  module UpdateModelMixin
    def update
      @record = self.get_record
      @record.update!(self.get_update_params)
      @serialized_record = self.get_serializer_class.new(
        object: @record, controller: self
      ).serialize
      return api_response(@serialized_record)
    end
  end

  module DestroyModelMixin
    def destroy
      @record = self.get_record
      @record.destroy!
      api_response(nil)
    end
  end

  module ReadOnlyModelControllerMixin
    include BaseModelControllerMixin
    def self.included(base)
      if base.is_a? Class
        BaseModelControllerMixin.included(base)
      end
    end

    include ListModelMixin
    include ShowModelMixin
  end

  module ModelControllerMixin
    include BaseModelControllerMixin
    def self.included(base)
      if base.is_a? Class
        BaseModelControllerMixin.included(base)
      end
    end

    include ListModelMixin
    include ShowModelMixin
    include CreateModelMixin
    include UpdateModelMixin
    include DestroyModelMixin
  end

end
