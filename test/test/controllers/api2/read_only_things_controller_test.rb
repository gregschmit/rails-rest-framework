require_relative '../base'


class Api2::ReadOnlyThingsControllerTest < ActionController::TestCase
  def test_list
    get :index, as: :json
    assert_response :success
    assert parsed_body[0]['name']
    assert parsed_body[0]['owner']
    assert_nil parsed_body[0]['calculated_property']
  end

  def test_show
    get :show, as: :json, params: {id: Thing.first.id}
    assert_response :success
    assert parsed_body['owner']
    assert_in_delta parsed_body['calculated_property'], 9.234, 0.01
  end
end
