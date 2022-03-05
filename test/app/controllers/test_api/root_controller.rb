class TestApi::RootController < TestApiController
  self.extra_actions = {nil: :get, blank: :get, unserializable: :get}

  def nil
    api_response(nil)
  end

  def blank
    api_response('')
  end
end
