class Api::Test::UserController < Api::TestController
  self.model = User

  class UsersSerializer < RESTFramework::NativeSerializer
    self.config = { only: [ :id, :login, :is_admin, :age ] }
  end

  self.singular = true
  self.fields = %w[login is_admin balance]
  # Singular controller: `add_action` is a member action, so `delegate` targets the record.
  add_action(:delegated, :get, metadata: { delegate: true })
  self.serializer_class = UsersSerializer

  def get_record
    User.first!
  end
end
