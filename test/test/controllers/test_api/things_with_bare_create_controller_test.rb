require_relative "../base"

class TestApi::ThingsWithBareCreateControllerTest < ActionController::TestCase
  def test_bare_create
    post(:create, as: :json, params: {name: "test_bare_create"})
    assert_response(:success)
    assert(Thing.find_by(name: "test_bare_create"))
  end
end
