class Api::Test::UsersWithBareCreateController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.fields = %w(id login)
  self.create_from_recordset = false
  self.model = User
end
