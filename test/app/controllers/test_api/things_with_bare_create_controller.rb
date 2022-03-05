class TestApi::ThingsWithBareCreateController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.fields = %w(id name)
  self.create_from_recordset = false
  self.model = Thing
end
