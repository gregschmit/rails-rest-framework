class TestApi::ThingsWithStringSerializerController < TestApiController
  include RESTFramework::ModelControllerMixin

  class ThingsSerializer < RESTFramework::NativeSerializer
    self.config = {only: [:id, :name, :price]}
  end

  self.fields = %w(id name)
  self.model = Thing
  self.serializer_class = "TestApi::ThingsWithStringSerializerController::ThingsSerializer"
end
