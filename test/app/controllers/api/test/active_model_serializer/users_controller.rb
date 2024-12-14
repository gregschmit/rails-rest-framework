class Api::Test::ActiveModelSerializer::UsersController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.serializer_class = UserSerializer
end
