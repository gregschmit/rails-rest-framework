if defined?(ActiveModel::Serializer)
  class ThingSerializer < ActiveModel::Serializer
    attributes :name, :shape
    has_one :owner
  end
end
