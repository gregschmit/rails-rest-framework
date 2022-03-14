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

  def test_can_get_blank
    get("/test_api/blank")
    assert_response(:success)
    get("/test_api/blank.json")
    assert_response(:no_content)
  end

  def test_can_get_things
    get("/test_api/things")
    assert_response(:success)
    get("/test_api/things.json")
    assert_response(:success)
  end

  def test_can_get_network_test
    get("/test_api/network/test")
    assert_response(:success)
    get("/test_api/network/test.json")
    assert_response(:success)
  end

  def test_thing_changed_action
    get("/test_api/thing/changed")
    assert_response(:success)
    get("/test_api/thing/changed.json")
    assert_response(:success)
  end

  def test_thing_another_changed_action
    get("/test_api/thing/another_changed")
    assert_response(:success)
    get("/test_api/thing/another_changed.json")
    assert_response(:success)
  end
end
