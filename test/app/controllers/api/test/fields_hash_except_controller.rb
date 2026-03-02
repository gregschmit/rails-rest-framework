class Api::Test::FieldsHashExceptController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.fields = { except: %w[balance] }
  self.model = User
end
