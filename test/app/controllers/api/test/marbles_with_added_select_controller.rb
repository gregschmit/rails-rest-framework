class Api::Test::MarblesWithAddedSelectController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.model = Marble
  self.native_serializer_config = {except: [:price]}

  def get_recordset
    return Marble.select("*, 5 as selected_value")
  end
end
