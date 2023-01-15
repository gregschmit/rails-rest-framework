class TestApi::MarblesWithFieldsHashController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.fields = {only: %w(id name radius_mm price), exclude: %w(radius_mm)}
  self.model = Marble
end
