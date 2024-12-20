class Api::TestController < ApiController
  include RESTFramework::BaseControllerMixin

  self.description = <<~TEXT.lines.map(&:strip).join(" ")
    The test API contains a lot of really weird controllers for testing specific features.
  TEXT

  before_action do
    @header_title = "Rails REST Framework Test API"
  end
end
