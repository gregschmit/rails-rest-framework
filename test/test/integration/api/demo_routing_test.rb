require "test_helper"

# The goal of this test is to ensure that the proper routes are defined for the demo API.
class Api::DemoRoutingTest < ActionDispatch::IntegrationTest
  def test_can_get_root
    get("/api/demo")
    assert_response(:success)
    get("/api/demo.json")
    assert_response(:success)
  end

  def test_can_get_users
    get("/api/demo/users")
    assert_response(:success)
    get("/api/demo/users.json")
    assert_response(:success)
  end

  # Only Rails>=8 due to changes in integration test behavior.
  if Rails::VERSION::MAJOR >= 8
    def test_can_not_get_network_resourceful_routes
      get("/api/demo/network.json")
      assert_response(:not_found)
      get("/api/demo/network")
      assert_response(:not_found)
    end
  end
end
