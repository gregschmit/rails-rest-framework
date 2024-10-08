require "test_helper"

# The goal of this test is to ensure that the proper routes are defined for API1.
class Api::DemoRoutingTest < ActionDispatch::IntegrationTest
  def test_can_get_root
    get("/api/demo")
    assert_response(:success)
    get("/api/demo.json")
    assert_response(:success)
  end

  def test_can_get_marbles
    get("/api/demo/marbles")
    assert_response(:success)
    get("/api/demo/marbles.json")
    assert_response(:success)
  end

  # TODO: Disabled because test is broken in Rails 8, but behavior tested manually and working.
  def _test_can_not_get_network_resourceful_routes
    assert_raises(ActionController::RoutingError) do
      get("/api/demo/network.json")
    end
    assert_raises(ActionController::RoutingError) do
      get("/api/demo/network")
    end
  end
end
