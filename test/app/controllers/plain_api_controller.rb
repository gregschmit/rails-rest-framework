class PlainApiController < ApplicationController
  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The plain API is a simple API that demonstrates the basic functionality of the framework.
  TEXT

  include RESTFramework::BaseControllerMixin

  before_action do
    @template_logo_text = "Rails REST Framework Plain API"
  end
end
