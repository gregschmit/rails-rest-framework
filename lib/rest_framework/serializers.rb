module RESTFramework
  class BaseSerializer
    attr_reader :errors

    def initialize(object: nil, data: nil, controller: nil, **kwargs)
      @object = object
      @data = data
      @controller = controller
    end
  end

  # This serializer uses `.as_json` to serialize objects. Despite the name, `.as_json` is a Rails
  # method which converts objects to Ruby primitives (with the top-level being either an array or a
  # hash).
  class NativeModelSerializer < BaseSerializer
    class_attribute :config
    class_attribute :singular_config
    class_attribute :plural_config
    class_attribute :action_config

    def initialize(model: nil, many: nil, **kwargs)
      super(**kwargs)
      @many = many
      @model = model || (@controller ? @controller.send(:get_model) : nil)
    end

    # Get controller action, if possible.
    def get_action
      return @controller&.action_name&.to_sym
    end

    # Get a locally defined configuration, if one is defined.
    def get_local_serializer_config
      action = self.get_action

      if action && self.action_config
        # index action should use :list serializer config if :index is not provided
        action = :list if action == :index && !self.action_config.key?(:index)

        return self.action_config[action] if self.action_config[action]
      end

      # no action_config, so try singular/plural config
      return self.plural_config if @many && self.plural_config
      return self.singular_config if !@many && self.singular_config

      # lastly, try the default config
      return self.config
    end

    # Get a configuration passable to `as_json` for the model.
    def get_serializer_config
      # return a locally defined serializer config if one is defined
      local_config = self.get_local_serializer_config
      return local_config if local_config

      # return a serializer config if one is defined
      serializer_config = @controller.send(:get_native_serializer_config)
      return serializer_config if serializer_config

      # otherwise, build a serializer config from fields
      fields = @controller.send(:get_fields) if @controller
      unless fields.blank?
        columns, methods = fields.partition { |f| f.to_s.in?(@model.column_names) }
        return {only: columns, methods: methods}
      end

      return {}
    end

    # Convert the object(s) to Ruby primitives.
    def serialize
      if @object
        @many = @object.respond_to?(:each) if @many.nil?
        return @object.as_json(self.get_serializer_config)
      end
      return nil
    end

    # Allow a serializer instance to be used as a hash directly in a nested serializer config.
    def [](key)
      unless instance_variable_defined?(:@_nested_config)
        @_nested_config = self.get_serializer_config
      end
      return @_nested_config[key]
    end
    def []=(key, value)
      unless instance_variable_defined?(:@_nested_config)
        @_nested_config = self.get_serializer_config
      end
      return @_nested_config[key] = value
    end

    # Allow a serializer class to be used as a hash directly in a nested serializer config.
    def self.[](key)
      unless instance_variable_defined?(:@_nested_config)
        @_nested_config = self.new.get_serializer_config
      end
      return @_nested_config[key]
    end
    def self.[]=(key, value)
      unless instance_variable_defined?(:@_nested_config)
        @_nested_config = self.new.get_serializer_config
      end
      return @_nested_config[key] = value
    end
  end
end
