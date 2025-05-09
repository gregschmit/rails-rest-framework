class Api::Test::FieldsHashOnlyExceptController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.fields = { only: %w[id login age balance], except: %w[balance] }
  self.model = User
end
