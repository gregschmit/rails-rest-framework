require_relative '../test_helper'

class Api1ControllerTest < ActionDispatch::IntegrationTest
  def test_can_hit_root
    get api1_url
    assert_response :success
  end

  def test_can_get_root_content
    get api1_url(format: :json)
    assert_equal JSON.parse(response.body)['message'], 'Welcome to your custom API1 root!'
  end
end
