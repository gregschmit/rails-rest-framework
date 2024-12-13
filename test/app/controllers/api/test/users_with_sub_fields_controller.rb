class Api::Test::UsersWithSubFieldsController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.model = User
  self.field_config = {
    manager: {sub_fields: [:id, :login, :balance]},
  }
end
