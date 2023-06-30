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

  def test_can_get_marbles
    get("/api/test/marbles")
    assert_response(:success)
    get("/api/test/marbles.json")
    assert_response(:success)
  end

  def test_can_get_network_test
    get("/api/test/network/test")
    assert_response(:success)
    get("/api/test/network/test.json")
    assert_response(:success)
  end

  def test_marble_changed_action
    get("/api/test/marble/changed")
    assert_response(:success)
    get("/api/test/marble/changed.json")
    assert_response(:success)
  end

  def test_marble_another_changed_action
    get("/api/test/marble/another_changed")
    assert_response(:success)
    get("/api/test/marble/another_changed.json")
    assert_response(:success)
  end
end
