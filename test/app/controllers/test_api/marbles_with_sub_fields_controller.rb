class TestApi::MarblesWithSubFieldsController < TestApiController
  include RESTFramework::ModelControllerMixin

  self.model = Marble
  self.field_config = {
    user: {sub_fields: [:id, :login, :balance]},
  }
end
