require "test_helper"

class Api::Test::ReadOnlyControllerTest < ActionController::TestCase
  def test_list
    get(:index, as: :json)
    assert_response(:success)
    assert(@response.parsed_body[0]["login"])
    refute(@response.parsed_body[0]["calculated_property"])
  end

  def test_show
    u = User.create!(login: "test_user")
    get(:show, as: :json, params: {id: u.id})
    assert_response(:success)
    assert_in_delta(@response.parsed_body["calculated_property"], 5.45, 0.01)
  end
end
