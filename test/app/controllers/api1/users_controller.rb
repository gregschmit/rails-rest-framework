class Api1::UsersController < Api1Controller
  include RESTFramework::ModelControllerMixin

  self.fields = [:login]
end
