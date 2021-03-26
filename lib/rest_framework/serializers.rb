class RESTFramework::BaseSerializer
  attr_reader :errors

  def initialize(object: nil, controller: nil, **kwargs)
    @object = object
    @controller = controller
  end
end


# This serializer uses `.as_json` to serialize objects. Despite the name, `.as_json` is an
# `ActiveModel` method which converts objects to Ruby primitives (with the top-level being either
# an array or a hash).
class RESTFramework::NativeSerializer < RESTFramework::BaseSerializer
  class_attribute :config
  class_attribute :singular_config
  class_attribute :plural_config
  class_attribute :action_config

  def initialize(many: nil, model: nil, **kwargs)
    super(**kwargs)

    if many.nil?
      # Determine if we are dealing with many objects or just one.
      @many = @object.respond_to?(:count) && @object.respond_to?(:each)
    else
      @many = many
    end

    @model = model || @controller.send(:get_model)
  end

  # Get controller action, if possible.
  def get_action
    return @controller&.action_name&.to_sym
  end

  # Get a locally defined native serializer configuration, if one is defined.
  def get_local_native_serializer_config
    action = self.get_action

    if action && self.action_config
      # Index action should use :list serializer config if :index is not provided.
      action = :list if action == :index && !self.action_config.key?(:index)

      return self.action_config[action] if self.action_config[action]
    end

    # No action_config, so try singular/plural config if explicitly instructed to via @many.
    return self.plural_config if @many == true && self.plural_config
    return self.singular_config if @many == false && self.singular_config

    # Lastly, try returning the default config, or singular/plural config in that order.
    return self.config || self.singular_config || self.plural_config
  end

  # Helper to get a native serializer configuration from the controller.
  def get_controller_native_serializer_config
    return nil unless @controller

    if @many == true
      controller_serializer = @controller.try(:native_serializer_plural_config)
    elsif @many == false
      controller_serializer = @controller.try(:native_serializer_singular_config)
    end

    return controller_serializer || @controller.try(:native_serializer_config)
  end

  # Get a configuration passable to `as_json` for the object.
  def get_serializer_config
    # Return a locally defined serializer config if one is defined.
    if local_config = self.get_local_native_serializer_config
      return local_config
    end

    # Return a serializer config if one is defined on the controller.
    if serializer_config = get_controller_native_serializer_config
      return serializer_config
    end

    # If the config wasn't determined, build a serializer config from model fields.
    fields = @controller.try(:get_fields) if @controller
    if fields
      if @model
        columns, methods = fields.partition { |f| f.in?(@model.column_names) }
      else
        columns = fields
        methods = []
      end

      return {only: columns, methods: methods}
    end

    # By default, pass an empty configuration, allowing the serialization of all columns.
    return {}
  end

  # Convert the object (record or recordset) to Ruby primitives.
  def serialize
    if @object
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


# Alias NativeModelSerializer -> NativeSerializer.
class RESTFramework::NativeModelSerializer < RESTFramework::NativeSerializer
  def initialize
    super
    ActiveSupport::Deprecation.new('1.0', 'rest_framework')
  end
end
