# The base serializer defines the interface for all REST Framework serializers.
class RESTFramework::BaseSerializer
  # Add `object` accessor to be compatible with `ActiveModel::Serializer`.
  attr_accessor :object

  # Accept/ignore `*args` to be compatible with the `ActiveModel::Serializer#initialize` signature.
  def initialize(object=nil, *args, controller: nil, **kwargs)
    @object = object
    @controller = controller
  end

  # The primary interface for extracting a native Ruby types. This works both for records and
  # collections. We accept and ignore `*args` for compatibility with `active_model_serializers`.
  def serialize(*args)
    raise NotImplementedError
  end

  # Synonym for `serialize` for compatibility with `active_model_serializers`.
  def serializable_hash(*args)
    return self.serialize(*args)
  end

  # For compatibility with `active_model_serializers`.
  def self.cache_enabled?
    return false
  end

  # For compatibility with `active_model_serializers`.
  def self.fragment_cache_enabled?
    return false
  end

  # For compatibility with `active_model_serializers`.
  def associations(*args, **kwargs)
    return []
  end
end

# This serializer uses `.serializable_hash` to convert objects to Ruby primitives (with the
# top-level being either an array or a hash).
class RESTFramework::NativeSerializer < RESTFramework::BaseSerializer
  class_attribute :config
  class_attribute :singular_config
  class_attribute :plural_config
  class_attribute :action_config

  # Accept/ignore `*args` to be compatible with the `ActiveModel::Serializer#initialize` signature.
  def initialize(object=nil, *args, many: nil, model: nil, **kwargs)
    super(object, *args, **kwargs)

    if many.nil?
      # Determine if we are dealing with many objects or just one.
      @many = @object.is_a?(Enumerable)
    else
      @many = many
    end

    # Determine model either explicitly, or by inspecting @object or @controller.
    @model = model
    @model ||= @object.class if @object.is_a?(ActiveRecord::Base)
    @model ||= @object[0].class if
      @many && @object.is_a?(Enumerable) && @object.is_a?(ActiveRecord::Base)

    @model ||= @controller.get_model if @controller
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
      controller_serializer = @controller.class.try(:native_serializer_plural_config)
    elsif @many == false
      controller_serializer = @controller.class.try(:native_serializer_singular_config)
    end

    return controller_serializer || @controller.class.try(:native_serializer_config)
  end

  # Helper to filter (mutate) a single subconfig for specific keys.
  def self.filter_subcfg(subcfg, except: nil, only: nil, additive: false)
    return subcfg unless except || only
    return subcfg unless subcfg || additive
    raise "Cannot pass `only` and `additive` to filter_subcfg." if only && additive

    if subcfg.is_a?(Array)
      subcfg = subcfg.map(&:to_sym)
      if except
        if additive
          # Only add fields which are not already included.
          subcfg += except - subcfg
        else
          subcfg -= except
        end
      elsif only
        # Ignore `additive` in an `only` context, since it could causing data leaking.
        unless additive
          subcfg.select! { |c| c.in?(only) }
        end
      end
    elsif subcfg.is_a?(Hash)
      # Additive doesn't make sense in a hash context since we wouldn't know the values.
      unless additive
        if except
          subcfg.symbolize_keys!
          subcfg.reject! { |k, _v| k.in?(except) }
        elsif only
          subcfg.symbolize_keys!
          subcfg.select! { |k, _v| k.in?(only) }
        end
      end
    elsif !subcfg
      if additive && except
        subcfg = except
      end
    else  # Subcfg is a single element (assume string/symbol).
      subcfg = subcfg.to_sym

      if except
        if subcfg.in?(except)
          subcfg = [] unless additive
        elsif additive
          subcfg = [subcfg, *except]
        end
      elsif only && !additive && !subcfg.in?(only)  # Protect only/additive data-leaking.
        subcfg = []
      end
    end

    return subcfg
  end

  # Helper to filter out configuration properties based on the :except query parameter.
  def filter_except(cfg)
    return cfg unless @controller

    except_param = @controller.class.try(:native_serializer_except_query_param)
    only_param = @controller.class.try(:native_serializer_only_query_param)
    if except_param && except = @controller.request.query_parameters[except_param].presence
      except = except.split(",").map(&:strip).map(&:to_sym)

      unless except.empty?
        # Filter `only`, `except` (additive), `include`, `methods`, and `serializer_methods`.
        if cfg[:only]
          cfg[:only] = self.class.filter_subcfg(cfg[:only], except: except)
        else
          cfg[:except] = self.class.filter_subcfg(cfg[:except], except: except, additive: true)
        end
        cfg[:include] = self.class.filter_subcfg(cfg[:include], except: except)
        cfg[:methods] = self.class.filter_subcfg(cfg[:methods], except: except)
        cfg[:serializer_methods] = self.class.filter_subcfg(
          cfg[:serializer_methods], except: except
        )
      end
    elsif only_param && only = @controller.request.query_parameters[only_param].presence
      only = only.split(",").map(&:strip).map(&:to_sym)

      unless only.empty?
        # For the `except` part of the serializer, we need to append any columns not in `only`.
        model = @controller.get_model
        except_cols = model&.column_names&.map(&:to_sym)&.reject { |c| c.in?(only) }

        # Filter `only`, `except` (additive), `include`, and `methods`.
        if cfg[:only]
          cfg[:only] = self.class.filter_subcfg(cfg[:only], only: only)
        else
          cfg[:except] = self.class.filter_subcfg(cfg[:except], except: except_cols, additive: true)
        end
        cfg[:include] = self.class.filter_subcfg(cfg[:include], only: only)
        cfg[:methods] = self.class.filter_subcfg(cfg[:methods], only: only)
        cfg[:serializer_methods] = self.class.filter_subcfg(cfg[:serializer_methods], only: only)
      end
    end

    return cfg
  end

  # Get the raw serializer config. Use `deep_dup` on any class mutables (array, hash, etc) to avoid
  # mutating class state.
  def _get_raw_serializer_config
    # Return a locally defined serializer config if one is defined.
    if local_config = self.get_local_native_serializer_config
      return local_config.deep_dup
    end

    # Return a serializer config if one is defined on the controller.
    if serializer_config = self.get_controller_native_serializer_config
      return serializer_config.deep_dup
    end

    # If the config wasn't determined, build a serializer config from model fields.
    fields = @controller.get_fields if @controller
    if fields
      fields = fields.deep_dup

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

  # Get a configuration passable to `serializable_hash` for the object, filtered if required.
  def get_serializer_config
    return filter_except(self._get_raw_serializer_config)
  end

  # Internal helper to serialize a single record and merge results of `serializer_methods`.
  def _serialize(record, config, serializer_methods)
    # Ensure serializer_methods is either falsy, or an array.
    if serializer_methods && !serializer_methods.respond_to?(:to_ary)
      serializer_methods = [serializer_methods]
    end

    # Merge serialized record with any serializer method results.
    return record.serializable_hash(config).merge(
      serializer_methods&.map { |m| [m.to_sym, self.send(m, record)] }.to_h,
    )
  end

  def serialize(*args)
    config = self.get_serializer_config
    serializer_methods = config.delete(:serializer_methods)

    if @object.respond_to?(:to_ary)
      return @object.map { |r| self._serialize(r, config, serializer_methods) }
    end

    return self._serialize(@object, config, serializer_methods)
  end

  # Allow a serializer instance to be used as a hash directly in a nested serializer config.
  def [](key)
    @_nested_config ||= self.get_serializer_config
    return @_nested_config[key]
  end

  def []=(key, value)
    @_nested_config ||= self.get_serializer_config
    return @_nested_config[key] = value
  end

  # Allow a serializer class to be used as a hash directly in a nested serializer config.
  def self.[](key)
    @_nested_config ||= self.new.get_serializer_config
    return @_nested_config[key]
  end

  def self.[]=(key, value)
    @_nested_config ||= self.new.get_serializer_config
    return @_nested_config[key] = value
  end
end

# :nocov:
# Alias NativeModelSerializer -> NativeSerializer.
class RESTFramework::NativeModelSerializer < RESTFramework::NativeSerializer
  def initialize(**kwargs)
    super
    ActiveSupport::Deprecation.warn(
      <<~MSG.split("\n").join(" "),
        RESTFramework::NativeModelSerializer is deprecated and will be removed in future versions of
        REST Framework; you should use RESTFramework::NativeSerializer instead.
      MSG
    )
  end
end
# :nocov:

# This is a helper factory to wrap an ActiveModelSerializer to provide a `serialize` method which
# accepts both collections and individual records. Use `.for` to build adapters.
class RESTFramework::ActiveModelSerializerAdapterFactory
  def self.for(active_model_serializer)
    return Class.new(active_model_serializer) do
      def serialize
        if self.object.respond_to?(:to_ary)
          return self.object.map { |r| self.class.superclass.new(r).serializable_hash }
        end

        return self.serializable_hash
      end
    end
  end
end
