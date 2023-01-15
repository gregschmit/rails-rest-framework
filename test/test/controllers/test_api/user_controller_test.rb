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
    assert_nil(@response.parsed_body["marbles"])
  end

  def test_with_marbles
    get(:with_marbles, as: :json)
    assert_response(:success)
    assert(@response.parsed_body["login"])
    assert_nil(@response.parsed_body["age"])
    assert_not_nil(@response.parsed_body["is_admin"])
    assert_nil(@response.parsed_body["balance"])
    assert(@response.parsed_body["marbles"])
    assert(@response.parsed_body["marbles"][0]["name"])
    assert_nil(@response.parsed_body["marbles"][0]["radius_mm"])
    assert_nil(@response.parsed_body["marbles"][0]["price"])
  end

  def test_delegated_method
    get(:delegated, as: :json)
    assert_response(:success)
    assert(@response.parsed_body["login"])
    assert_not_nil(@response.parsed_body["is_admin"])
    assert_nil(@response.parsed_body["age"])
  end
end
