class Api::Demo::UsersController < Api::DemoController
  self.model = User

  self.field_config = {
    status: { options: User::STATUS_OPTS },
    phone_number: { sub_fields: [ :id, :number ] },
  }
end
