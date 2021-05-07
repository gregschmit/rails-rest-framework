require_relative '../test_helper'


# The goal of this test is to ensure that the proper routes are defined for API1.
class Api1RoutingTest < ActionDispatch::IntegrationTest
  def test_can_get_root
    get '/api1'
    assert_response :success
    get '/api1.json'
    assert_response :success
  end

  def can_get_root_test
    get '/api1/test'
    assert_response :success
    get '/api1/test.json'
    assert_response :success
  end

  def test_can_get_things
    get '/api1/things'
    assert_response :success
    get '/api1/things.json'
    assert_response :success
  end

  def test_can_not_get_network_resourceful_routes
    assert_raises ActionController::RoutingError do
      get "/api1/network.json"
    end
    assert_raises ActionController::RoutingError do
      get "/api1/network"
    end
  end
end
