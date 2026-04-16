class Api::Test::FieldsHashOnlyController < Api::TestController
  self.model = User
  self.fields = { only: %w[id login age balance] }
end
