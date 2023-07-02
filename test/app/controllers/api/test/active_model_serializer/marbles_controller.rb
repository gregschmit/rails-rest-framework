class Api::Test::ActiveModelSerializer::MarblesController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.serializer_class = MarbleSerializer
end
