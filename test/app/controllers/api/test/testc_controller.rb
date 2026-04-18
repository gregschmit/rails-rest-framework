class Api::Test::TestcController < Api::TestController
  include RESTFramework::Controller
  self.model = Testc
end
