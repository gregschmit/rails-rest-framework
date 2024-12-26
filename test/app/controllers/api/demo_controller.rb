class Api::DemoController < ApiController
  include RESTFramework::BaseControllerMixin

  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The demo API is a more complex API that demonstrates the framework's more advanced features,
    primarily paginationn, nested resources, and integration with Action Text and Active Storage.
  TEXT

  self.enable_action_text = true
  self.enable_active_storage = true

  self.page_size = 30

  class_attribute(:native_serializer_associations_limit, default: 6, instance_accessor: false)
  class_attribute(
    :native_serializer_include_associations_count, default: true, instance_accessor: false
  )
  class_attribute(
    :filter_backends,
    default: [
      RESTFramework::QueryFilter,
      RESTFramework::OrderingFilter,
      RESTFramework::SearchFilter,
      RESTFramework::RansackFilter,
    ],
    instance_accessor: false,
  )

  self.paginator_class = RESTFramework::PageNumberPaginator

  before_action do
    @header_title = "Rails REST Framework Demo API"
  end
end
