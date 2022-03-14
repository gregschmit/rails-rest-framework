require_relative "base"

class TestApi::NetworkControllerTest < ActionController::TestCase
  include BaseTestApiControllerTests

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
