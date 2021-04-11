class Api2::ThingsController < Api2Controller
  include RESTFramework::ModelControllerMixin

  class ThingsSerializer < RESTFramework::NativeSerializer
    self.action_config = {list: {only: [:id, :name, :price]}}
    self.singular_config = {
      only: [:id, :name, :shape],
      include: {owner: Api2::UserController::UsersSerializer.new(many: false)},
    }
    self.plural_config = {only: [:id, :name]}
  end

  self.fields = %w(id name)
  self.ordering_fields = %w(id name price)
  self.action_fields = {create: %w(name), update: %w(name)}
  self.paginator_class = RESTFramework::PageNumberPaginator
  self.page_size = 2
  self.serializer_class = ThingsSerializer
  self.extra_actions = {alternate_list: :get}

  def alternate_list
    return self.index
  end
end
