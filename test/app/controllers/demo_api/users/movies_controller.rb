class DemoApi::Users::MoviesController < DemoApiController
  include RESTFramework::ModelControllerMixin

  def get_recordset
    return User.find(params[:user_id]).movies
  end
end
