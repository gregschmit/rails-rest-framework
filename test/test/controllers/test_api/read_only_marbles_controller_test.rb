require_relative "base"

class TestApi::ReadOnlyMarblesControllerTest < ActionController::TestCase
  include BaseTestApiControllerTests

  def test_list
    get(:index, as: :json)
    assert_response(:success)
    assert(@response.parsed_body[0]["name"])
    assert(@response.parsed_body[0]["user"])
    refute(@response.parsed_body[0]["calculated_property"])
  end

  def test_show
    t = Marble.create!(name: "test", user_attributes: {login: "test"})
    get(:show, as: :json, params: {id: t.id})
    assert_response(:success)
    assert(@response.parsed_body["user"])
    assert_in_delta(@response.parsed_body["calculated_property"], 9.234, 0.01)
  end
end
