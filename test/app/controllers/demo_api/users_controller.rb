class DemoApi::UsersController < DemoApiController
  include RESTFramework::ModelControllerMixin

  self.field_config = {
    status: {options: User::STATUS_OPTS},
    phone_number: {sub_fields: [:id, :number]},
  }
end
