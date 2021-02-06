class Api1::UsersController < Api1Controller
  include RESTFramework::ModelControllerMixin

  self.fields = %w(login is_admin balance)
  self.allowed_action_parameters = {
    create: %w(login age),
    update: %w(login age is_admin balance),
  }
end
