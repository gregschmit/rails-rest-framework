# TestApi should test advanced functionality of the REST framework.
class TestApiController < ApplicationController
  include RESTFramework::BaseControllerMixin

  self.page_size = 2

  before_action do
    @template_logo_text = "Rails REST Framework Test API"
  end
end

module TestApi
end
