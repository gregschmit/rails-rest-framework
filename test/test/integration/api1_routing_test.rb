require_relative '../test_helper'


# The goal of this test is to ensure that the proper routes are defined for API1.
class Api1RoutingTest < ActionDispatch::IntegrationTest
  def test_can_get_root
    get '/api1'
    assert_response :success
    get '/api1.json'
    assert_response :success
  end

  def test_can_get_things
    get '/api1/things'
    assert_response :success
    get '/api1/things.json'
    assert_response :success
  end
end
