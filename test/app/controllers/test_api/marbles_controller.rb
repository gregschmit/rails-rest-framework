class TestApi::MarblesController < TestApiController
  include RESTFramework::BulkModelControllerMixin

  class MarblesSerializer < RESTFramework::NativeSerializer
    self.action_config = {list: {only: [:id, :name, :price]}}
    self.singular_config = {
      only: [:id, :name, :radius_mm],
      include: {user: TestApi::UserController::UsersSerializer.new(many: false)},
      serializer_methods: :id_plus_one,
    }
    self.plural_config = {only: [:id, :name]}

    def id_plus_one(record)
      return record.id + 1
    end
  end

  self.fields = %w(id name)
  self.ordering_fields = %w(id name price)
  self.action_fields = {create: %w(name), update: %w(name)}
  self.paginator_class = RESTFramework::PageNumberPaginator
  self.page_size = 2
  self.serializer_class = MarblesSerializer
  self.extra_collection_actions = {alternate_list: :get}
  self.extra_member_actions = {description: :get}
  self.filter_backends = [
    RESTFramework::ModelFilter, RESTFramework::ModelOrderingFilter, RESTFramework::ModelSearchFilter
  ]

  def alternate_list
    return self.index
  end

  def description
    record = self.get_record
    return api_response({message: "This is record #{record.id} (#{record.name})"})
  end
end
