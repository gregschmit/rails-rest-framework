class TestApi::User::ThingsController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.fields = %w(id name)

  def get_recordset
    return User.first!.things
  end
end
