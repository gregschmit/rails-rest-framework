require "test_helper"

# The goal of this test is to ensure that the proper routes are defined for API2.
class TestApiRoutingTest < ActionDispatch::IntegrationTest
  setup { Rails.application.load_seed }

  def test_can_get_root
    get("/test_api")
    assert_response(:success)
    get("/test_api.json")
    assert_response(:success)
  end

  def test_can_get_marbles
    get("/test_api/marbles")
    assert_response(:success)
    get("/test_api/marbles.json")
    assert_response(:success)
  end

  def test_can_get_network_test
    get("/test_api/network/test")
    assert_response(:success)
    get("/test_api/network/test.json")
    assert_response(:success)
  end

  def test_marble_changed_action
    get("/test_api/marble/changed")
    assert_response(:success)
    get("/test_api/marble/changed.json")
    assert_response(:success)
  end

  def test_marble_another_changed_action
    get("/test_api/marble/another_changed")
    assert_response(:success)
    get("/test_api/marble/another_changed.json")
    assert_response(:success)
  end
end
