require "test_helper"

class Api::Test::FieldsHashOnlyExceptControllerTest < ActionController::TestCase
  def test_list
    get(:index, as: :json)
    assert_response(:success)
    assert_equal(
      [
        "id",
        "login",
        "age",
      ].sort,
      @response.parsed_body[0].keys.sort,
    )
  end

  # Test actions that shouldnt've changed.

  def test_show
    id = User.first.id
    get(:show, params: { id: id })
    assert_response(:success)
  end

  def test_show_not_found
    id = User.all.pluck(:id).max + 1
    get(:show, params: { id: id })
    assert_response(404)
  end

  def test_create
    post(:create, as: :json, params: { login: "test with fields hash", age: 1 })
    assert_response(:success)
    assert(User.find_by(id: @response.parsed_body["id"]))
  end
end
