class Api::Test::UsersWithHiddenController < Api::TestController
  include RESTFramework::BulkModelControllerMixin

  self.model = User
  self.fields = { include: [ :random1, :random2 ] }
  self.field_config = {
    random1: { hidden: true },
    random2: { hidden_from_index: true },
  }
end
