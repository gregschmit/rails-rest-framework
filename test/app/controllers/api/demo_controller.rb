class Api::DemoController < ApiController
  include RESTFramework::Controller

  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The demo API is a more complex API that demonstrates the framework's more advanced features,
    primarily pagination, nested resources, and integration with Action Text and Active Storage.
  TEXT

  self.description = DESCRIPTION
  self.openapi_include_children = true

  # Shared across all demo resources, so propagate to descendants.
  propagate do
    self.bulk = true
    self.bulk_allow_mode_override = true

    self.enable_action_text = true
    self.enable_active_storage = true

    # Pagination is on by default (`PageNumberPaginator`); the demo customizes the page size and
    # opts out of the default `max_page_size` cap so it can showcase the `?page_size=0` unpaginated
    # escape hatch (which requires no cap).
    self.page_size = 30
    self.max_page_size = nil

    self.native_serializer_associations_limit = 6
    self.native_serializer_include_associations_count = true
    self.filter_backends = [
      RESTFramework::QueryFilter,
      RESTFramework::OrderingFilter,
      RESTFramework::SearchFilter,
      RESTFramework::RansackFilter,
    ]
  end

  # A propagated extra action: every demo controller and its descendants get `ping`.
  add_action(:ping, :get, propagate: true)

  # A descendants-only extra action: demo resource controllers get `child_ping`, but not this base.
  add_action(:child_ping, :get, propagate: :exclude_self)

  # Root-only extra actions, local to this base so they don't leak onto demo resource controllers.
  add_action(:nil, :get)
  add_action(:blank, :get)
  add_action(:echo, :post)

  before_action do
    @header_title = "Rails REST Framework Demo API"
  end

  def index_content
    { message: self.class.description }
  end

  def ping
    render_api({ message: "pong" })
  end

  def child_ping
    render_api({ message: "child pong" })
  end

  def nil
    render(api: nil)
  end

  def blank
    render(api: "")
  end

  def echo
    render(api: { message: "Here is your data:", data: request.request_parameters })
  end
end
