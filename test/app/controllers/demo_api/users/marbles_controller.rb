class DemoApi::Users::MarblesController < DemoApiController
  include RESTFramework::ModelControllerMixin

  def get_recordset
    return User.find(params[:user_id]).marbles
  end
end
