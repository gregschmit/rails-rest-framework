# The Demo API should test very simple functionality of the REST framework, and will be deployed to
# Heroku for demo purposes.
class DemoApiController < ApplicationController
  include RESTFramework::BaseControllerMixin

  before_action do
    @template_logo_text = "Rails REST Framework Demo API"
  end
end
