class Api::Test::MarblesWithFieldsHashController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.fields = {only: %w(id name radius_mm price), exclude: %w(radius_mm)}
  self.model = Marble
end
