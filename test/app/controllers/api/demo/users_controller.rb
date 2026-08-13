class Api::Demo::UsersController < Api::DemoController
  self.model = User

  self.fields = {
    config: {
      status: { options: User::STATUS_OPTS },
      phone_number: { fields: [ :id, :number ] },
      favorite: { fields: [ :name, :price ] },
    },
  }
end
