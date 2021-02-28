class Api2::ThingController < Api2Controller
  include RESTFramework::ReadOnlyModelControllerMixin

  self.fields = ['id', 'name']
  self.singleton_controller = true

  def get_record
    return Thing.first
  end
end
