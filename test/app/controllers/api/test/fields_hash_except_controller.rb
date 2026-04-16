class Api::Test::FieldsHashExceptController < Api::TestController
  self.model = User
  self.fields = { except: %w[balance] }
end
