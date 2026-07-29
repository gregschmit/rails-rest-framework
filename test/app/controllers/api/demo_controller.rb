class Api::DemoController < ApiController
  include RESTFramework::Controller

  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The demo API is a more complex API that demonstrates the framework's more advanced features,
    primarily pagination, nested resources, and integration with Action Text and Active Storage.
  TEXT

  # Shared across all demo resources, so propagate to descendants.
  propagate do
    self.bulk = true
    self.bulk_allow_mode_override = true

    self.enable_action_text = true
    self.enable_active_storage = true

    self.page_size = 30

    self.native_serializer_associations_limit = 6
    self.native_serializer_include_associations_count = true
    self.filter_backends = [
      RESTFramework::QueryFilter,
      RESTFramework::OrderingFilter,
      RESTFramework::SearchFilter,
      RESTFramework::RansackFilter,
    ]

    self.paginator_class = RESTFramework::PageNumberPaginator
  end

  # A propagated extra action: every demo controller and its descendants get `ping`.
  add_collection_action(:ping, :get, propagate: true)

  # A descendants-only extra action: demo resource controllers get `child_ping`, but not this base.
  add_collection_action(:child_ping, :get, propagate: :exclude_self)

  before_action do
    @header_title = "Rails REST Framework Demo API"
  end

  def ping
    render_api({ message: "pong" })
  end

  def child_ping
    render_api({ message: "child pong" })
  end
end
