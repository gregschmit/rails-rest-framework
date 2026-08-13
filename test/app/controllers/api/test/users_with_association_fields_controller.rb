class Api::Test::UsersWithAssociationFieldsController < Api::TestController
  self.model = User
  self.fields = {
    config: {
      manager: { fields: [ :id, :login, :balance ] },
    },
  }
end
