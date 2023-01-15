class TestApi::ActiveModelSerializer::MarblesController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.serializer_class = MarbleSerializer
end
