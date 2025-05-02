if defined?(ActiveModel::Serializer)
  class UserSerializer < ActiveModel::Serializer
    attributes :login, :age, :test_serializer_method
    has_one :manager

    def test_serializer_method
      "working!"
    end
  end
end
