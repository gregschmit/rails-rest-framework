require_relative '../test_helper'

class Api1ControllerTest < ActionDispatch::IntegrationTest
  def test_can_hit_root
    get "#{api1_url}.json"
    assert_equal @response.status, 200
  end
end
