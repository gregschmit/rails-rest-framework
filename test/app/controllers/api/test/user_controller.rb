class Api::Test::UserController < Api::TestController
  include RESTFramework::ModelControllerMixin

  class UsersSerializer < RESTFramework::NativeSerializer
    self.config = {only: [:id, :login, :is_admin, :age]}
  end

  self.singleton_controller = true
  self.fields = %w(login is_admin balance)
  self.extra_actions = {with_marbles: :get}
  self.extra_member_actions = {delegated: {methods: :get, metadata: {delegate: true}}}
  self.serializer_class = UsersSerializer

  def get_record
    return User.first!
  end
end
