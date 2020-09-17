class Api2::ReadOnlyThingsController < Api2Controller
  include RESTFramework::ReadOnlyModelControllerMixin

  @model = Thing
  @fields = %w(id name)
end
