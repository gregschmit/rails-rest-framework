class Api::Test::NoRescueUnknownFormatController < Api::TestController
  self.model = User
  self.fields = %w[id login]
  self.rescue_unknown_format_with = false
end
