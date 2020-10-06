module RESTFramework
  class BaseSerializer
    attr_reader :errors

    def initialize(object: nil, data: nil, controller: nil, **kwargs)
      @object = object
      @data = data
      @controller = controller
    end

    def is_valid
      return true
    end
  end

  # This serializer uses `.as_json` to serialize objects. Despite the name, `.as_json` is a Rails
  # method which converts objects to Ruby primitives (with the top-level being either an array or a
  # hash).
  class NativeModelSerializer < BaseSerializer
    def initialize(model: nil, **kwargs)
      super(**kwargs)
      @model = model || @controller.send(:get_model)
    end

    # Get a configuration passable to `as_json` for the model.
    def get_native_serializer_config
      # return a serializer config if one is defined
      serializer_config = @controller.send(:get_native_serializer_config)
      return serializer_config if serializer_config

      # build serializer config from fields
      fields = @controller.send(:get_fields)
      unless fields.blank?
        columns, methods = fields.partition { |f| f.to_s.in?(@model.column_names) }
        return {only: columns, methods: methods}
      end

      return {}
    end

    # Convert the object(s) to Ruby primitives.
    def serialize
      if @object
        return @object.as_json(self.get_native_serializer_config)
      end
      return nil
    end
  end
end
