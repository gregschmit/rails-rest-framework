class Api2::ThingsWithBareCreateController < Api2Controller
  include RESTFramework::ModelControllerMixin

  self.fields = %w(id name)
  self.create_from_recordset = false
  self.model = Thing
end
