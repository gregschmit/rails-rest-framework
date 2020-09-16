class ApiController < ActionController::Base
  include RESTFramework::ModelControllerMixin

  def test_root
    render inline: "Test successful!"
  end
end

module Api
end
