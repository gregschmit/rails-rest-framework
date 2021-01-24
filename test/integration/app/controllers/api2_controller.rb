class Api2Controller < ApplicationController
  include RESTFramework::BaseControllerMixin

  self.page_size = 2
end

module Api2
end
