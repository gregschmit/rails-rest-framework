class Api1Controller < ApplicationController
  include RESTFramework::ModelControllerMixin
  layout 'rest_framework'

  def root
    api_response({message: "Welcome to your API root!"})
  end
end

module Api1
end
