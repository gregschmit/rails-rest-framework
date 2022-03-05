# The Demo API should test very simple functionality of the REST framework, and will be deployed to
# Heroku for demo purposes.
class DemoApiController < ApplicationController
  include RESTFramework::BaseControllerMixin

  self.extra_actions = {test: :get}

  def root
    api_response({message: "Welcome to the Demo API!"})
  end

  def test
    api_response({message: "Test successful!"})
  end
end

module DemoApi
end
