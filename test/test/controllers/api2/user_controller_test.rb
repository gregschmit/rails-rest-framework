require_relative '../base'


class Api2::UserControllerTest < ActionController::TestCase
  def test_show
    get :show, as: :json
    assert_response :success
    assert _parsed_body['login']
    assert_not_nil _parsed_body['is_admin']
    assert _parsed_body['age']
    assert_nil _parsed_body['balance']
    assert_nil _parsed_body['things']
  end

  def test_with_things
    get :with_things, as: :json
    assert_response :success
    assert _parsed_body['login']
    assert_nil _parsed_body['age']
    assert_not_nil _parsed_body['is_admin']
    assert_nil _parsed_body['balance']
    assert _parsed_body['things']
    assert _parsed_body['things'][0]['name']
    assert_nil _parsed_body['things'][0]['shape']
    assert_nil _parsed_body['things'][0]['price']
  end
end
