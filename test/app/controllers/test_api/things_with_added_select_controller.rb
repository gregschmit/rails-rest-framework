class TestApi::ThingsWithAddedSelectController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.model = Thing
  self.native_serializer_config = {except: [:price]}

  def get_recordset
    return super.select("*, 5 as selected_value")
  end
end
