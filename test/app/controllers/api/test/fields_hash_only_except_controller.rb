class Api::Test::FieldsHashOnlyExceptController < Api::TestController
  self.model = User
  self.fields = { only: %w[id login age balance], except: %w[balance] }
end
