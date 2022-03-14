class TestApi::ThingController < TestApiController
  include RESTFramework::ReadOnlyModelControllerMixin

  self.fields = ["id", "name"]
  self.extra_actions = {
    changed_action: {methods: [:get], path: :changed},
    another_changed: {methods: :get, action: :another_changed_action},
  }

  # Custom action to test different action/path params in routing.
  def changed_action
    record = self.get_record
    api_response({changed: record.updated_at})
  end

  # Another custom action to test different action/path params in routing.
  def another_changed_action
    record = self.get_record
    api_response({another_changed: record.updated_at})
  end

  def get_record
    return Thing.first
  end
end
