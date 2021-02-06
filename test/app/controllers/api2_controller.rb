# Api2 should test advanced functionality of the REST framework.
class Api2Controller < ApplicationController
  include RESTFramework::BaseControllerMixin

  self.page_size = 2
end

module Api2
end
