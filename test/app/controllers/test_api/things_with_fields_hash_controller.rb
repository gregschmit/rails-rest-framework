class TestApi::ThingsWithFieldsHashController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.fields = {only: %w(id name shape price), exclude: %w(shape)}
  self.model = Thing
end
