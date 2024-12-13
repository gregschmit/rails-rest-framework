class Api::Test::UsersWithStringSerializerController < Api::TestController
  include RESTFramework::ModelControllerMixin

  class UsersSerializer < RESTFramework::NativeSerializer
    self.config = {only: [:id, :login, :age]}
  end

  self.fields = %w(id login)
  self.model = User
  self.serializer_class = "Api::Test::UsersWithStringSerializerController::UsersSerializer"
end
