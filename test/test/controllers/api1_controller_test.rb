require_relative './base'


class Api1ControllerTest < ActionController::TestCase
  include BaseApiControllerTests

  def test_root_contains_correct_message
    message = "Welcome to your custom API1 root!"
    get :root, as: :json
    assert_response :success
    assert parsed_body['message'] == message
  end
end
