class Api::Test::MarblesWithBareCreateController < Api::TestController
  include RESTFramework::ModelControllerMixin

  self.fields = %w(id name)
  self.create_from_recordset = false
  self.model = Marble
end
