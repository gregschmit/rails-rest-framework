class Api2::ThingController < Api2Controller
  include RESTFramework::ReadOnlyModelControllerMixin

  @fields = ['id', 'name']
  @singleton_controller = true

  def get_record
    return Thing.first
  end
end
