class Api::Demo::Users::MoviesController < Api::DemoController
  self.model = Movie

  def get_recordset
    User.find(params[:user_id]).movies
  end
end
