require_relative '../test_helper'

# The goal of this test is to ensure that the proper routes are defined for API1.
class Api1RoutingTest < ActionDispatch::IntegrationTest
  test "can get root" do
    get '/api1'
    assert_response :success
    get '/api1.json'
    assert_response :success
  end

  test "can get things" do
    get '/api1/things'
    assert_response :success
    get '/api1/things.json'
    assert_response :success
  end

  test "can create but not destroy things" do
    post '/api1/things.json', params: {name: 'test'}
    assert_response :success
    get '/api1/things.json'
    id = JSON.parse(@response.body)[0]['id'].to_i
    refute_equal id, 0
    assert_raises ActionController::RoutingError do
      delete "/api1/things/#{id}.json"
    end
  end
end
