require_relative "../base"

class TestApi::UserControllerTest < ActionController::TestCase
  def test_show
    get(:show, as: :json)
    assert_response(:success)
    assert(parsed_body["login"])
    assert_not_nil(parsed_body["is_admin"])
    assert(parsed_body["age"])
    assert_nil(parsed_body["balance"])
    assert_nil(parsed_body["things"])
  end

  def test_with_things
    get(:with_things, as: :json)
    assert_response(:success)
    assert(parsed_body["login"])
    assert_nil(parsed_body["age"])
    assert_not_nil(parsed_body["is_admin"])
    assert_nil(parsed_body["balance"])
    assert(parsed_body["things"])
    assert(parsed_body["things"][0]["name"])
    assert_nil(parsed_body["things"][0]["shape"])
    assert_nil(parsed_body["things"][0]["price"])
  end
end
