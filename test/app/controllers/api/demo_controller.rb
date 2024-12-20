class Api::DemoController < ApiController
  include RESTFramework::BaseControllerMixin

  self.description = <<~TEXT.lines.map(&:strip).join(" ")
    The demo API is a more complex API that demonstrates the framework's more advanced features,
    primarily pagination and nested resources.
  TEXT

  class_attribute(:page_size, default: 30)
  class_attribute(:native_serializer_associations_limit, default: 6)
  class_attribute(:native_serializer_include_associations_count, default: true)
  class_attribute(
    :filter_backends,
    default: [
      RESTFramework::QueryFilter,
      RESTFramework::OrderingFilter,
      RESTFramework::SearchFilter,
      RESTFramework::RansackFilter,
    ],
  )

  self.paginator_class = RESTFramework::PageNumberPaginator

  before_action do
    @header_title = "Rails REST Framework Demo API"
  end
end
