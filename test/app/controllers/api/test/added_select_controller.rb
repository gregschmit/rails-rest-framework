class Api::Test::AddedSelectController < Api::TestController
  self.model = Movie
  self.fields = { include: [ :selected_value ] }

  def get_recordset
    Movie.select("*, 5 as selected_value")
  end
end
