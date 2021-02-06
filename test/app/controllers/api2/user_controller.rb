class Api2::UserController < Api2Controller
  include RESTFramework::ModelControllerMixin

  self.singleton_controller = true
  self.fields = %w(login is_admin balance)

  def get_record
    return User.first!
  end
end
