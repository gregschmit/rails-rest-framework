# TestApi should test advanced functionality of the REST framework.
class TestApiController < ApplicationController
  include RESTFramework::BaseControllerMixin

  before_action do
    @template_logo_text = "Rails REST Framework Test API"
  end

  def root
    api_response({message: <<~TXT.lines.map(&:strip).join(" ")})
      Welcome to the Rails REST Framework Test API. This API is for unit tests for features not
      covered by the Demo API.
    TXT
  end
end
