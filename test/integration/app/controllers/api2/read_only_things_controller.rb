class Api2::ReadOnlyThingsController < Api2Controller
  include RESTFramework::ReadOnlyModelControllerMixin

  self.model = Thing
  self.fields = %w(id name)
end
