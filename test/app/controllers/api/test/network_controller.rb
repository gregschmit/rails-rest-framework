class Api::Test::NetworkController < Api::TestController
  add_action(:test, :get)

  def test
    render(api: { message: "Hello, this is your non-resourceful route!" })
  end
end
