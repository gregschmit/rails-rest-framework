require_relative '../test_helper'

# The goal of this test is to ensure that the proper routes are defined for API2.
class Api2RoutingTest < ActionDispatch::IntegrationTest
  test "can get root" do
    get '/api2'
    assert_response :success
    get '/api2.json'
    assert_response :success
  end

  test "can get nil/blank/truly_blank" do
    get '/api2/nil'
    assert_response :success
    get '/api2/nil.json'
    assert_response :success
    get '/api2/blank'
    assert_response :success
    get '/api2/blank.json'
    assert_response :success
    get '/api2/truly_blank'
    assert_response :success
    get '/api2/truly_blank.json'
    assert_response :no_content
  end

  test "can get things" do
    get '/api2/things'
    assert_response :success
    get '/api2/things.json'
    assert_response :success
  end

  test "can get network test" do
    get '/api2/network/test'
    assert_response :success
    get '/api2/network/test.json'
    assert_response :success
  end

  test "can not get network resourceful routes" do
    assert_raises ActionController::RoutingError do
      get "/api1/network.json"
    end
    assert_raises ActionController::RoutingError do
      get "/api1/network"
    end
  end
end
