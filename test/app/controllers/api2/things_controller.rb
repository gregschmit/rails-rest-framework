class Api2::ThingsController < Api2Controller
  include RESTFramework::ModelControllerMixin

  self.fields = %w(id name)
  self.action_fields = {
    create_fields: %w(name),
    update_fields: %w(name),
  }
  self.paginator_class = RESTFramework::PageNumberPaginator
  self.page_size = 2
end
