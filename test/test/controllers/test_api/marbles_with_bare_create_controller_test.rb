require_relative "base"

class TestApi::MarblesWithBareCreateControllerTest < ActionController::TestCase
  include BaseTestApiControllerTests

  def test_bare_create
    post(:create, as: :json, params: {name: "test_bare_create"})
    assert_response(:success)
    assert(Marble.find_by(name: "test_bare_create"))
  end
end
