class Api::Test::BareCreateController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.model = Movie
  self.fields = %w(id name)
  self.create_from_recordset = false
end
