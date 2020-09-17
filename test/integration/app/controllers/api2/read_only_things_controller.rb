class Api2::ReadOnlyThingsController < Api2Controller
  include RESTFramework::ReadOnlyModelControllerMixin

  @model = Thing
  @fields = ['id', 'name']
end
