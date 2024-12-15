class Api::Test::AddedSelectController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.model = Movie
  self.fields = {include: [:selected_value]}

  def get_recordset
    return Movie.select("*, 5 as selected_value")
  end
end
