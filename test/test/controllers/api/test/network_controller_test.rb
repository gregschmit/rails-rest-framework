require_relative "base"

class Api::Test::NetworkControllerTest < ActionController::TestCase
  include BaseApi::TestControllerTests

  def test_cannot_list
    assert_raises(ActionController::UrlGenerationError) do
      get(:index)
    end
  end

  def test_can_get_test_action
    get(:test, as: :json)
    assert_response(:success)
    assert(@response.parsed_body["message"] == "Hello, this is your non-resourceful route!")
  end
end
