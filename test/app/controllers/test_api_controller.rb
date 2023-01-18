class TestApiController < ApplicationController
  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The test API contains a lot of really weird controllers for unit testing specific features.
  TEXT

  include RESTFramework::BaseControllerMixin

  before_action do
    @template_logo_text = "Rails REST Framework Test API"
  end
end
