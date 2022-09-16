class TestApi::ThingsWithAddedSelectController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.model = Thing

  def get_recordset
    return super.select("*, 5 as selected_value")
  end
end
