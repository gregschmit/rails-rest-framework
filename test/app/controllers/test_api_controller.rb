# TestApi should test advanced functionality of the REST framework.
class TestApiController < ApplicationController
  include RESTFramework::BaseControllerMixin

  self.page_size = 2
end

module TestApi
end
