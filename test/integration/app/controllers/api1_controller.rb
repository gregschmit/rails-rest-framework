class Api1Controller < ApplicationController
  include RESTFramework::ModelControllerMixin

  def root
    render inline: "Test successful on API1!"
  end
end

module Api1
end
