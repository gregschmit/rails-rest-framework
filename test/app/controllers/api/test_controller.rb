class Api::TestController < ApiController
  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The test API contains a lot of really weird controllers for testing specific features.
  TEXT

  include RESTFramework::BaseControllerMixin

  before_action do
    @header_title = "Rails REST Framework Test API"
  end
end
