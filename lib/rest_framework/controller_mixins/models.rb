require_relative 'base'
require_relative '../filters'

module RESTFramework

  module BaseModelControllerMixin
    include BaseControllerMixin
    def self.included(base)
      if base.is_a? Class
        BaseControllerMixin.included(base)

        # Add class attributes (with defaults) unless they already exist.
        {
          # Core attributes related to models.
          model: nil,
          recordset: nil,

          # Attributes for create/update parameters.
          allowed_parameters: nil,
          allowed_action_parameters: nil,

          # Attributes for configuring record fields.
          fields: nil,
          action_fields: nil,

          # Attributes for the default native serializer.
          native_serializer_config: nil,
          native_serializer_action_config: nil,

          # Attributes for default model filtering (and ordering).
          filterset_fields: nil,
          ordering_fields: nil,
          ordering_query_param: 'ordering',

          # Other misc attributes.
          disable_creation_from_recordset: nil,  # Option to disable `recordset.create` behavior.
        }.each do |a, default|
          unless base.respond_to?(a)
            base.class_attribute(a)

            # Set default manually so we can still support Rails 4. Maybe later we can use the
            # default parameter on `class_attribute`.
            base.send(:"#{a}=", default)
          end
        end
      end
    end

    protected

    # Helper to get the configured serializer class, or `NativeModelSerializer` as a default.
    def get_serializer_class
      return self.class.serializer_class || NativeModelSerializer
    end

    # Get a list of parameters allowed for the current action.
    def get_allowed_parameters
      allowed_action_parameters = self.class.allowed_action_parameters || {}
      action = self.action_name.to_sym

      # index action should use :list allowed parameters if :index is not provided
      action = :list if action == :index && !allowed_action_parameters.key?(:index)

      return (allowed_action_parameters[action] if action) || self.class.allowed_parameters
    end

    # Get the list of filtering backends to use.
    def get_filter_backends
      backends = super
      return backends if backends

      # By default, return the standard model filter backend.
      return [RESTFramework::ModelFilter, RESTFramework::ModelOrderingFilter]
    end

    # Get a list of fields for the current action.
    def get_fields
      action_fields = self.class.action_fields || {}
      action = self.action_name.to_sym

      # index action should use :list fields if :index is not provided
      action = :list if action == :index && !action_fields.key?(:index)

      return (action_fields[action] if action) || self.class.fields || []
    end

    # Filter the request body for keys in current action's allowed_parameters/fields config.
    def get_body_params
      fields = self.get_allowed_parameters || self.get_fields
      return @get_body_params ||= (request.request_parameters.select { |p|
        fields.include?(p.to_sym) || fields.include?(p.to_s)
      })
    end
    alias :get_create_params :get_body_params
    alias :get_update_params :get_body_params

    # Get a record by `id` or return a single record if recordset is filtered down to a single
    # record.
    def get_record
      records = self.get_filtered_data(self.get_recordset)
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

  module ShowModelMixin
    def show
      @record = self.get_record
      serialized_record = self.get_serializer_class.new(object: @record, controller: self).serialize
      return api_response(serialized_record)
    end
  end

  module CreateModelMixin
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

  module UpdateModelMixin
    def update
      @record = self.get_record
      @record.update!(self.get_update_params)
      serialized_record = self.get_serializer_class.new(object: @record, controller: self).serialize
      return api_response(serialized_record)
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
