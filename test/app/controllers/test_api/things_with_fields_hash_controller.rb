class TestApi::ThingsWithFieldsHashController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.fields = {only: %w(id name shape price), except: %w(shape)}
  self.model = Thing
end
