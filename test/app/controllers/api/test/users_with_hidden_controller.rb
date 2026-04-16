class Api::Test::UsersWithHiddenController < Api::TestController
  self.model = User
  self.bulk = true
  self.fields = { include: [ :random1, :random2 ] }
  self.field_config = {
    random1: { hidden: true },
    random2: { hidden_from_index: true },
  }
end
