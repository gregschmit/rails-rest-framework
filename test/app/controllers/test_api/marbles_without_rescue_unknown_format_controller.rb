class TestApi::MarblesWithoutRescueUnknownFormatController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.fields = %w(id name)
  self.model = Marble
  self.rescue_unknown_format_with = false
end
