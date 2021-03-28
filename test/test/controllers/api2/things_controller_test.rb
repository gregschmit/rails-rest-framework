require_relative '../base'


class Api2::ThingsControllerTest < ActionController::TestCase
  def test_list
    get :index, as: :json
    assert_response :success
    assert _parsed_body['results'][0]['name']
    assert_nil _parsed_body['results'][0]['shape']
  end
end
