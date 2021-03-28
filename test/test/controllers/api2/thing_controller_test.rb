require_relative '../base'


class Api2::ThingControllerTest < ActionController::TestCase
  def test_show
    get :show, as: :json
    assert_response :success
    assert _parsed_body['name']
    assert_nil _parsed_body['shape']
  end

  def test_changed_action
    get :changed_action, as: :json
    assert_response :success
    assert _parsed_body['changed']
    assert_nil _parsed_body['name']
  end

  def test_another_changed_action
    get :another_changed_action, as: :json
    assert_response :success
    assert _parsed_body['another_changed']
    assert_nil _parsed_body['name']
  end
end
