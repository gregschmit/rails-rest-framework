require_relative "base"

class TestApi::UserControllerTest < ActionController::TestCase
  include BaseTestApiControllerTests

  def test_show
    get(:show, as: :json)
    assert_response(:success)
    assert(@response.parsed_body["login"])
    assert_not_nil(@response.parsed_body["is_admin"])
    assert(@response.parsed_body["age"])
    assert_nil(@response.parsed_body["balance"])
    assert_nil(@response.parsed_body["things"])
  end

  def test_with_things
    get(:with_things, as: :json)
    assert_response(:success)
    assert(@response.parsed_body["login"])
    assert_nil(@response.parsed_body["age"])
    assert_not_nil(@response.parsed_body["is_admin"])
    assert_nil(@response.parsed_body["balance"])
    assert(@response.parsed_body["things"])
    assert(@response.parsed_body["things"][0]["name"])
    assert_nil(@response.parsed_body["things"][0]["shape"])
    assert_nil(@response.parsed_body["things"][0]["price"])
  end
end
