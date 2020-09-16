require_relative 'base'

module RESTFramework

  module BaseModelControllerMixin
    include BaseControllerMixin

    # By default (and for now), we will just use `as_json`, but we should consider supporting:
    #   active_model_serializers (problem:
    #     https://github.com/rails-api/active_model_serializers#whats-happening-to-ams)
    #   fast_jsonapi (really good and fast serializers)
    #@serializer
    #@list_serializer
    #@show_serializer
    #@create_serializer
    #@update_serializer

    module ClassMethods
      extend ClassMethodHelpers
      include BaseControllerMixin::ClassMethods

      _restframework_attr_reader(:model)
      _restframework_attr_reader(:recordset)
      _restframework_attr_reader(:singleton_controller)

      _restframework_attr_reader(:fields)
      _restframework_attr_reader(:list_fields)
      _restframework_attr_reader(:show_fields)
      _restframework_attr_reader(:create_fields)
      _restframework_attr_reader(:update_fields)

      _restframework_attr_reader(:extra_member_actions, default: {})

      # For model-based mixins, `@extra_collection_actions` is synonymous with `@extra_actions`.
      def extra_actions
        return (
          _restframework_try_class_level_variable_get(:extra_collection_actions) ||
          _restframework_try_class_level_variable_get(:extra_actions, default: {})
        )
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    protected

    # Get a list of fields for the current action.
    def get_fields
      return @fields if @fields

      # index action should use list_fields
      name = (action_name == 'index') ? 'list' : action_name

      begin
        @fields = self.class.send("#{name}_fields")
      rescue NameError
      end
      @fields ||= self.class.fields || []

      return @fields
    end

    # Get a configuration passable to `as_json` for the model.
    def get_model_serializer_config
      fields = self.get_fields
      unless fields.blank?
        columns, methods = fields.partition { |f| f.to_s.in?(self.get_model.column_names) }
        return {only: columns, methods: methods}
      end
      return {}
    end

    # Filter the request body for keys allowed by the current action's field config.
    def _get_field_values_from_request_body
      return @_get_field_values_from_request_body ||= (request.request_parameters.select { |p|
        self.get_fields.include?(p.to_sym) || self.get_fields.include?(p.to_s)
      })
    end
    alias :get_create_params :_get_field_values_from_request_body
    alias :get_update_params :_get_field_values_from_request_body

    # Filter params for keys allowed by the current action's field config.
    def _get_field_values_from_params
      return @_get_field_values_from_params ||= params.permit(*self.get_fields)
    end
    alias :get_lookup_params :_get_field_values_from_params
    alias :get_filter_params :_get_field_values_from_params

    # Get the recordset, filtered by the filter params.
    def get_filtered_recordset
      filter_params = self.get_filter_params
      unless filter_params.blank?
        return self.get_recordset.where(**self.get_filter_params)
      end
      return self.get_recordset
    end

    # Get a record by `id` or return a single record if recordset is filtered down to a single record.
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
    private def _get_model(from_internal_get_recordset: false)
      return @model if @model
      return self.class.model if self.class.model
      unless from_get_recordset  # prevent infinite recursion
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
    private def _get_recordset(from_internal_get_model: false)
      return @recordset if @recordset
      return self.class.recordset if self.class.recordset
      unless from_get_model  # prevent infinite recursion
        model = self._get_model(from_internal_get_recordset: true)
        return (@recordset = model.all) if model
      end
      return nil
    end

    # Get the model for this controller.
    def get_model
      return _get_model
    end

    # Get the base set of records this controller has access to.
    def get_recordset
      return _get_recordset
    end
  end

  module ListModelMixin
    # TODO: pagination classes like Django
    def index
      @records = self.get_filtered_recordset
      api_response(@records, **self.get_model_serializer_config)
    end
  end

  module ShowModelMixin
    def show
      @record = self.get_record
      api_response(@record, **self.get_model_serializer_config)
    end
  end

  module CreateModelMixin
    def create
      begin
        @record = self.get_model.create!(self.get_create_params)
      rescue ActiveRecord::RecordInvalid => e
        api_response(e.record.messages, status: 400)
      end
      api_response(@record, **self.get_model_serializer_config)
    end
  end

  module UpdateModelMixin
    def update
      @record = self.get_record
      if @record
        @record.attributes(self.get_update_params)
        @record.save!
        api_response(@record, **self.get_model_serializer_config)
      else
        api_response({detail: "Record not found."}, status: 404)
      end
    end
  end

  module DestroyModelMixin
    def destroy
      @record = self.get_record
      if @record
        @record.destroy!
        api_response('')
      else
        api_response({detail: "Method 'DELETE' not allowed."}, status: 405)
      end
    end
  end

  module ReadOnlyModelControllerMixin
    include BaseModelControllerMixin
    def self.included(base)
      base.extend BaseModelControllerMixin::ClassMethods
    end

    include ListModelMixin
    include ShowModelMixin
  end

  module ModelControllerMixin
    include BaseModelControllerMixin
    def self.included(base)
      base.extend BaseModelControllerMixin::ClassMethods
    end

    include ListModelMixin
    include ShowModelMixin
    include CreateModelMixin
    include UpdateModelMixin
    include DestroyModelMixin
  end

end
