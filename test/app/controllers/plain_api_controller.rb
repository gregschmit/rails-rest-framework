# This API should test the default configuration of the REST framework.
class PlainApiController < ApplicationController
  include RESTFramework::BaseControllerMixin
end
