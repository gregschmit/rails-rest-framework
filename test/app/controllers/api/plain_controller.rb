class Api::PlainController < ApiController
  # TODO: We use the old mixin here to test for regressions; remove in 2.0.
  include RESTFramework::BaseControllerMixin

  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The plain API is a simple API that demonstrates the basic functionality of the framework.
  TEXT

  before_action do
    @header_title = "Rails REST Framework Plain API"
  end
end
