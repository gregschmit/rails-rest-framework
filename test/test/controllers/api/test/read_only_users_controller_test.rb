require_relative "base"

class Api::Test::ReadOnlyUsersControllerTest < ActionController::TestCase
  include BaseApi::TestControllerTests

  def test_list
    get(:index, as: :json)
    assert_response(:success)
    puts @response.parsed_body
    assert(@response.parsed_body[0]["login"])
    refute(@response.parsed_body[0]["calculated_property"])
  end

  def test_show
    u = User.create!(login: "test_user", manager_attributes: {login: "test_manager"})
    get(:show, as: :json, params: {id: u.id})
    assert_response(:success)
    assert(@response.parsed_body["manager"])
    assert_in_delta(@response.parsed_body["calculated_property"], 5.45, 0.01)
  end
end
