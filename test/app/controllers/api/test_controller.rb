class Api::TestController < ApiController
  include RESTFramework::BaseControllerMixin

  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The test API contains a lot of really weird controllers for testing specific features.
  TEXT

  self.description = DESCRIPTION

  self.enable_action_text = true
  self.enable_active_storage = true

  before_action do
    @header_title = "Rails REST Framework Test API"
  end
end
