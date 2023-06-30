require_relative "base"

class Api::Test::MarblesWithBareCreateControllerTest < ActionController::TestCase
  include BaseApi::TestControllerTests

  def test_bare_create
    post(:create, as: :json, params: {name: "test_bare_create"})
    assert_response(:success)
    assert(Marble.find_by(name: "test_bare_create"))
  end
end
