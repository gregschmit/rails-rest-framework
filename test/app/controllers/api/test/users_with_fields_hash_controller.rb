class Api::Test::UsersWithFieldsHashController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.fields = {only: %w(id login age balance), exclude: %w(balance)}
  self.model = User
end
