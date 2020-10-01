class Api1Controller < ApplicationController
  include RESTFramework::BaseControllerMixin

  def root
    api_response({message: "Welcome to your custom API1 root!"})
  end
end

module Api1
end
