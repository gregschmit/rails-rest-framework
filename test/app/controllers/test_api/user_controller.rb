class TestApi::UserController < TestApiController
  include RESTFramework::ModelControllerMixin

  class UsersSerializer < RESTFramework::NativeSerializer
    self.config = {only: [:id, :login, :is_admin, :age]}
    self.action_config = {
      with_things: {
        only: [:id, :login, :is_admin],
        include: {things: TestApi::ThingsController::ThingsSerializer.new(many: true)},
      },
    }
  end

  self.singleton_controller = true
  self.fields = %w(login is_admin balance)
  self.extra_actions = {with_things: :get}
  self.serializer_class = UsersSerializer

  def with_things
    return self.show
  end

  def get_record
    return User.first!
  end
end
