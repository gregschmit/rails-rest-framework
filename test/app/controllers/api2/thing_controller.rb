class Api2::ThingController < Api2Controller
  include RESTFramework::ReadOnlyModelControllerMixin

  self.fields = ['id', 'name']
  self.singleton_controller = true
  self.extra_actions = {changed_action: {methods: [:get], path: :changed}}

  # Custom action if the thing changed.
  def changed_action
    record = self.get_record
    api_response({changed: record.updated_at})
  end

  protected

  def get_record
    return Thing.first
  end
end
