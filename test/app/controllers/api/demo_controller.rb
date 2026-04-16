class Api::DemoController < ApiController
  include RESTFramework::Controller

  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The demo API is a more complex API that demonstrates the framework's more advanced features,
    primarily pagination, nested resources, and integration with Action Text and Active Storage.
  TEXT

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

  before_action do
    @header_title = "Rails REST Framework Demo API"
  end
end
