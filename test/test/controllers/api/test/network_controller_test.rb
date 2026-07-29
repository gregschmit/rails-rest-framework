require "test_helper"

class Api::Test::NetworkControllerTest < ActionController::TestCase
  def test_index_serves_the_root
    # A modelless controller's index renders `index_content` (its root), not a resource list.
    get(:index)
    assert_response(:success)
  end

  def test_can_get_test_action
    get(:test, as: :json)
    assert_response(:success)
    assert(@response.parsed_body["message"] == "Hello, this is your non-resourceful route!")
  end
end
