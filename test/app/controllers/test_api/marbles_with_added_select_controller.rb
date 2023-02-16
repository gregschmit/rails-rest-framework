class TestApi::MarblesWithAddedSelectController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.native_serializer_config = {except: [:price]}

  def get_recordset
    return Marble.select("*, 5 as selected_value")
  end
end
