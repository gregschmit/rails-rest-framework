require_relative "./base"

class DemoApiControllerTest < ActionController::TestCase
  include BaseApiControllerTests

  def test_root_contains_correct_message
    message = "Welcome to the Demo API!"
    get(:root, as: :json)
    assert_response(:success)
    assert_equal(message, parsed_body["message"])
  end
end
