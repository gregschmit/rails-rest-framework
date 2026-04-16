class Api::Test::UsersWithSubFieldsController < Api::TestController
  self.model = User
  self.field_config = {
    manager: { sub_fields: [ :id, :login, :balance ] },
  }
end
