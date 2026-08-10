class Api::Test::JsonColumnController < Api::TestController
  self.model = User
  self.fields = %w[id login preferences]
end
