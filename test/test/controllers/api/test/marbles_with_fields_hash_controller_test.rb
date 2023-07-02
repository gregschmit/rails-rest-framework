require_relative "base"

class Api::Test::MarblesWithFieldsHashControllerTest < ActionController::TestCase
  include BaseApi::TestControllerTests

  def test_list
    get(:index, as: :json)
    assert_response(:success)
    assert_equal(
      [
        "id",
        "name",
        "price",
      ].sort,
      @response.parsed_body[0].keys.sort,
    )
  end

  # Test actions that shouldnt've changed.

  def test_show
    id = Marble.first.id
    get(:show, params: {id: id})
    assert_response(:success)
  end

  def test_show_not_found
    id = Marble.all.pluck(:id).max + 1
    get(:show, params: {id: id})
    assert_response(404)
  end

  def test_create
    post(:create, as: :json, params: {name: "test with fields hash", price: 1})
    assert_response(:success)
    assert(Marble.find_by(id: @response.parsed_body["id"]))
  end
end
