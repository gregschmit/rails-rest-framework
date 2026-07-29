class Api::TestController < ApiController
  include RESTFramework::Controller

  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The test API contains a lot of really weird controllers for testing specific features.
  TEXT

  self.description = DESCRIPTION

  # Shared across all test resources, so propagate to descendants.
  propagate do
    self.enable_action_text = true
    self.enable_active_storage = true
  end

  before_action do
    @header_title = "Rails REST Framework Test API"
  end
end
