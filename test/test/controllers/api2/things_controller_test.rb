require_relative '../base'


class Api2::ThingsControllerTest < ActionController::TestCase
  def test_list
    get :index, as: :json
    assert_response :success
    assert _parsed_body['results'][0]['price']
    assert_nil _parsed_body['results'][0]['shape']
  end

  def test_alternate_list
    get :alternate_list, as: :json
    assert_response :success
    assert _parsed_body['results'][0]['name']
    assert_nil _parsed_body['results'][0]['shape']
    assert_nil _parsed_body['results'][0]['price']
  end

  def test_show
    get :show, as: :json, params: {id: Thing.first.id}
    assert_response :success
    assert _parsed_body['shape']
    assert_nil _parsed_body['price']
  end
end
