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

    # These controllers assert on raw serialized output, so opt out of the default pagination; this
    # also keeps the index code path that skips pagination under test. Controllers that specifically
    # test pagination re-enable it locally (e.g. `Api::Test::UsersController`).
    self.paginator_class = nil
  end

  before_action do
    @header_title = "Rails REST Framework Test API"
  end

  def index_content
    { message: self.class.description }
  end
end
