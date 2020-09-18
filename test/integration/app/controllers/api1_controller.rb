class Api1Controller < ApplicationController
  include RESTFramework::ModelControllerMixin

  def root
    api_response({message: "Welcome to your custom API1 root!"})
  end
end

module Api1
end
