class DemoApi::UsersController < DemoApiController
  include RESTFramework::BulkModelControllerMixin

  self.field_config = {
    status: {options: User::STATUS_OPTS},
    phone_number: {sub_fields: [:id, :number]},
  }
end
