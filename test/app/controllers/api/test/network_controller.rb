class Api::Test::NetworkController < Api::TestController
  include RESTFramework::BaseControllerMixin

  self.extra_actions = {test: :get}

  def test
    render_api({message: "Hello, this is your non-resourceful route!"})
  end
end
