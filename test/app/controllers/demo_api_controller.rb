# The Demo API should test very simple functionality of the REST framework, and will be deployed to
# Heroku for demo purposes.
class DemoApiController < ApplicationController
  include RESTFramework::BaseControllerMixin

  # TODO: Add root_controller for DemoApi since that's the suggested method. Change Test API to have
  # root inside the inherited controller like an idiot.
  self.extra_actions = {test: :get}

  before_action do
    @template_logo_text = "Rails REST Framework Demo API"
  end

  def root
    api_response({message: "Welcome to the Rails REST Framework Demo API!"})
  end

  def test
    api_response({message: "Test successful!"})
  end
end

module DemoApi
end
