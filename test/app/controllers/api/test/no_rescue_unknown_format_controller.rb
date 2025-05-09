class Api::Test::NoRescueUnknownFormatController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.fields = %w[id login]
  self.model = User
  self.rescue_unknown_format_with = false
end
