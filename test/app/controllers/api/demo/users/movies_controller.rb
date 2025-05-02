class Api::Demo::Users::MoviesController < Api::DemoController
  include RESTFramework::BulkModelControllerMixin

  def get_recordset
    User.find(params[:user_id]).movies
  end
end
