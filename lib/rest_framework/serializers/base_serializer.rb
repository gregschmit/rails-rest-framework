# The base serializer defines the interface for all REST Framework serializers.
class RESTFramework::Serializers::BaseSerializer
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

# Alias for convenience.
RESTFramework::BaseSerializer = RESTFramework::Serializers::BaseSerializer
