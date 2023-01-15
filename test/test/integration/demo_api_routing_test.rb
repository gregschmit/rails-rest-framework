require "test_helper"

# The goal of this test is to ensure that the proper routes are defined for API1.
class DemoApiRoutingTest < ActionDispatch::IntegrationTest
  def test_can_get_root
    get("/demo_api")
    assert_response(:success)
    get("/demo_api.json")
    assert_response(:success)
  end

  def test_can_get_marbles
    get("/demo_api/marbles")
    assert_response(:success)
    get("/demo_api/marbles.json")
    assert_response(:success)
  end

  def test_can_not_get_network_resourceful_routes
    assert_raises(ActionController::RoutingError) do
      get("/demo_api/network.json")
    end
    assert_raises(ActionController::RoutingError) do
      get("/demo_api/network")
    end
  end
end
