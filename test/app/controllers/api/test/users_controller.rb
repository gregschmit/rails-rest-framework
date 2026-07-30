class Api::Test::UsersController < Api::TestController
  self.model = User
  self.bulk = true

  class UsersSerializer < RESTFramework::NativeSerializer
    self.action_config = { list: { only: [ :id, :login ] } }
    self.singular_config = {
      only: [ :id, :login, :balance ],
      include: { manager: Api::Test::UserController::UsersSerializer.new(many: false) },
      serializer_methods: :id_plus_one,
    }
    self.plural_config = { only: [ :id, :login ] }

    def id_plus_one(record)
      record.id + 1
    end
  end

  self.fields = %w[id login]
  self.ordering_fields = %w[id login balance]
  self.paginator_class = RESTFramework::PageNumberPaginator
  self.page_size = 2
  self.serializer_class = UsersSerializer
  add_action(:alternate_list, :get, type: :collection)
  add_action(:description, :get, type: :member)

  # Same-named delegated actions: the collection route delegates to `User.status_keys` (class
  # method), the member route to `record.status_keys` — exercising scope disambiguation.
  add_action(:status_keys, :get, type: :collection, metadata: { delegate: true })
  add_action(:status_keys, :get, type: :member, metadata: { delegate: true })

  # Delegated member actions exercising argument passing and the `public_send` guard.
  add_action(:echo_kwargs, :get, type: :member, metadata: { delegate: true })
  add_action(:echo_kwargs_with_block, :get, type: :member, metadata: { delegate: true })
  add_action(:echo_positional, :get, type: :member, metadata: { delegate: true })
  add_action(:returns_nil, :get, type: :member, metadata: { delegate: true })
  add_action(:self_record, :get, type: :member, metadata: { delegate: true })
  add_action(:secret, :get, type: :member, metadata: { delegate: true })

  def alternate_list
    self.index
  end

  def description
    record = self.get_record
    render(api: { message: "This is record #{record.id} (#{record.login})" })
  end

  # A method sharing the delegated `status_keys` action's name: dispatch is route-based, so the
  # delegated routes must never reach this (the delegation tests would fail if they did).
  def status_keys
    render_api({ should_not_be_reached: true })
  end
end
