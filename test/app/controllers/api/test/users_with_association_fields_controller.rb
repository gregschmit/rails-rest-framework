class Api::Test::UsersWithAssociationFieldsController < Api::TestController
  self.model = User
  self.field_config = {
    manager: { fields: [ :id, :login, :balance ] },
  }
end
