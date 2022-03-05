class TestApi::ActiveModelSerializer::ThingsController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.serializer_class = ThingSerializer
end
