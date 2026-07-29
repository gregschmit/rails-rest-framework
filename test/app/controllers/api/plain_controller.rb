class Api::PlainController < ApiController
  include RESTFramework::Controller

  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The plain API is a simple API that demonstrates the basic functionality of the framework.
  TEXT

  self.description = DESCRIPTION

  before_action do
    @header_title = "Rails REST Framework Plain API"
  end

  def index_content
    { message: self.class.description }
  end
end
