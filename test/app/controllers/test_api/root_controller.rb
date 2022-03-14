class TestApi::RootController < TestApiController
  self.extra_actions = {nil: :get, blank: :get, unserializable: :get}

  def root
    api_response({message: <<~TXT.lines.map(&:strip).join(" ")})
      Welcome to the Rails REST Framework Test API. This API is for unit tests for features not
      covered by the Demo API.
    TXT
  end

  def nil
    api_response(nil)
  end

  def blank
    api_response("")
  end
end
