class Api::Test::ActiveModelSerializer::UsersController < Api::TestController
  self.model = User
  self.serializer_class = UserSerializer
end
