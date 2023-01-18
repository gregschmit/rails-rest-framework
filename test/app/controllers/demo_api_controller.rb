class DemoApiController < ApplicationController
  DESCRIPTION = <<~TEXT.lines.map(&:strip).join(" ")
    The demo API is a more complex API that demonstrates the framework's more advanced features,
    primarily pagination and nested resources.
  TEXT

  include RESTFramework::BaseControllerMixin

  class_attribute(:page_size, default: 30)
  class_attribute(:native_serializer_associations_limit, default: 6)
  class_attribute(:native_serializer_include_associations_count, default: true)

  self.paginator_class = RESTFramework::PageNumberPaginator

  before_action do
    @template_logo_text = "Rails REST Framework Demo API"
  end
end
