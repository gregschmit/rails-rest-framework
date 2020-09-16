class Api::RootController < ApiController
  include RESTFramework::ModelControllerMixin

  def root
    render inline: "Test successful!"
  end
end
