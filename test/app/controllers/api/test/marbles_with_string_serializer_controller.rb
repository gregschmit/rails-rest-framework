class Api::Test::MarblesWithStringSerializerController < Api::TestController
  include RESTFramework::ModelControllerMixin

  class MarblesSerializer < RESTFramework::NativeSerializer
    self.config = {only: [:id, :name, :price]}
  end

  self.fields = %w(id name)
  self.model = Marble
  self.serializer_class = "Api::Test::MarblesWithStringSerializerController::MarblesSerializer"
end
