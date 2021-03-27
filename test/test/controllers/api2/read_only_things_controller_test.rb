require_relative '../base'


class Api2::ReadOnlyThingsControllerTest < ActionController::TestCase
  def test_list
    get :index, as: :json
    assert_response :success
    assert _parsed_body[0]['name']
    assert _parsed_body[0]['owner']
    assert_nil _parsed_body[0]['calculated_property']
  end

  def test_show
    get :show, as: :json, params: {id: Thing.first.id}
    assert_response :success
    assert _parsed_body['owner']
    assert_in_delta _parsed_body['calculated_property'], 9.234, 0.01
  end
end
