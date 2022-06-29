class TestApi::ThingsWithoutRescueUnknownFormatController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.fields = %w(id name)
  self.model = Thing
  self.rescue_unknown_format_with = false
end
