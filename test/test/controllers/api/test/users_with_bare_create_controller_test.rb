require_relative "base"

class Api::Test::UsersWithBareCreateControllerTest < ActionController::TestCase
  include BaseApi::TestControllerTests

  def test_bare_create
    post(:create, as: :json, params: {login: "test_bare_create"})
    assert_response(:success)
    assert(User.find_by(login: "test_bare_create"))
  end
end
