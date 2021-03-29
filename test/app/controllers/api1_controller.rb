# Api1 should test very simple functionality of the REST framework.
class Api1Controller < ApplicationController
  include RESTFramework::BaseControllerMixin

  self.extra_actions = {test: :get}

  def root
    api_response({message: "Welcome to your custom API1 root!"})
  end

  def test
    api_response({message: "Test successful!"})
  end
end

module Api1
end
