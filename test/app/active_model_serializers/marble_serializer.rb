if defined?(ActiveModel::Serializer)
  class MarbleSerializer < ActiveModel::Serializer
    attributes :name, :radius_mm, :test_serializer_method
    has_one :user

    def test_serializer_method
      return "working!"
    end
  end
end
