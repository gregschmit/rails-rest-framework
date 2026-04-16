class Api::Test::UserController < Api::TestController
  self.model = User

  # This will reproduce a failure condition in the router when it attemts to resolve which builtin
  # actions it should skip.
  undef_method :index

  class UsersSerializer < RESTFramework::NativeSerializer
    self.config = { only: [ :id, :login, :is_admin, :age ] }
  end

  self.singleton_controller = true
  self.fields = %w[login is_admin balance]
  self.extra_member_actions = { delegated: { methods: :get, metadata: { delegate: true } } }
  self.serializer_class = UsersSerializer

  def get_record
    User.first!
  end
end
