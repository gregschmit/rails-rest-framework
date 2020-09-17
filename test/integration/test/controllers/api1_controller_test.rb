require_relative '../test_helper'

class Api1ControllerTest < ActionDispatch::IntegrationTest
  def test_can_hit_root
    get api1_url
    assert_equal @response.body, "Test successful on API1!"
  end
end
