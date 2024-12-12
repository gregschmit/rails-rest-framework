class Api::Test::UsersController < Api::TestController
  include RESTFramework::BulkModelControllerMixin

  class UsersSerializer < RESTFramework::NativeSerializer
    self.action_config = {list: {only: [:id, :login]}}
    self.singular_config = {
      only: [:id, :login, :balance],
      include: {manager: Api::Test::UserController::UsersSerializer.new(many: false)},
      serializer_methods: :id_plus_one,
    }
    self.plural_config = {only: [:id, :login]}

    def id_plus_one(record)
      return record.id + 1
    end
  end

  self.fields = %w(id login)
  self.ordering_fields = %w(id login balance)
  self.paginator_class = RESTFramework::PageNumberPaginator
  self.page_size = 2
  self.serializer_class = UsersSerializer
  self.extra_collection_actions = {alternate_list: :get}
  self.extra_member_actions = {description: :get}
  self.filter_backends = [
    RESTFramework::ModelOrderingFilter,
    RESTFramework::ModelQueryFilter,
    RESTFramework::ModelSearchFilter,
  ]

  def alternate_list
    return self.index
  end

  def description
    record = self.get_record
    return api_response({message: "This is record #{record.id} (#{record.login})"})
  end
end
