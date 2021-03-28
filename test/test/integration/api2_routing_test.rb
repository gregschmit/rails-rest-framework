require_relative '../test_helper'


# The goal of this test is to ensure that the proper routes are defined for API2.
class Api2RoutingTest < ActionDispatch::IntegrationTest
  def test_can_get_root
    get '/api2'
    assert_response :success
    get '/api2.json'
    assert_response :success
  end

  def test_can_get_blank
    get '/api2/blank'
    assert_response :success
    get '/api2/blank.json'
    assert_response :no_content
  end

  def test_can_get_things
    get '/api2/things'
    assert_response :success
    get '/api2/things.json'
    assert_response :success
  end

  def test_can_get_network_test
    get '/api2/network/test'
    assert_response :success
    get '/api2/network/test.json'
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
