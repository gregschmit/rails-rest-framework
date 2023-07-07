# This is a helper factory to wrap an ActiveModelSerializer to provide a `serialize` method which
# accepts both collections and individual records. Use `.for` to build adapters.
class RESTFramework::Serializers::ActiveModelSerializerAdapterFactory
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

# Alias for convenience.
# rubocop:disable Layout/LineLength
RESTFramework::ActiveModelSerializerAdapterFactory = RESTFramework::Serializers::ActiveModelSerializerAdapterFactory
# rubocop:enable Layout/LineLength
