class DemoApi::Users::ThingsController < DemoApiController
  include RESTFramework::ModelControllerMixin

  def get_recordset
    return User.find(params[:user_id]).things
  end
end
