require "test_helper"

# The goal of this test is to ensure that the proper routes are defined for API2.
class Api::TestRoutingTest < ActionDispatch::IntegrationTest
  setup { Rails.application.load_seed }

  def test_can_get_root
    get("/api/test")
    assert_response(:success)
    get("/api/test.json")
    assert_response(:success)
  end

  def test_can_get_users
    get("/api/test/users")
    assert_response(:success)
    get("/api/test/users.json")
    assert_response(:success)
  end

  def test_can_get_network_test
    get("/api/test/network/test")
    assert_response(:success)
    get("/api/test/network/test.json")
    assert_response(:success)
  end
end
