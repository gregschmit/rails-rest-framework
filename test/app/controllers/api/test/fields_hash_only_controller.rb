class Api::Test::FieldsHashOnlyController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.fields = { only: %w[id login age balance] }
  self.model = User
end
