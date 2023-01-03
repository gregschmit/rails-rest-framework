# This API should demo functionality of the REST framework.
class DemoApiController < ApplicationController
  include RESTFramework::BaseControllerMixin

  before_action do
    @template_logo_text = "Rails REST Framework Demo API"
  end
end
