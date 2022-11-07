if defined?(ActiveModel::Serializer)
  class ThingSerializer < ActiveModel::Serializer
    attributes :name, :shape, :test_serializer_method
    has_one :owner

    def test_serializer_method
      return "working!"
    end
  end
end
