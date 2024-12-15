class Api::Test::UsersWithAddedSelectController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.model = User
  self.native_serializer_config = {except: [:balance]}

  def get_recordset
    return User.select("*, 5 as selected_value")
  end
end
