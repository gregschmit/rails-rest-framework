require_relative "base"

class Api::Test::BareCreateControllerTest < ActionController::TestCase
  include BaseApi::TestControllerTests

  def test_bare_create
    post(:create, as: :json, params: {name: "Test Bare Create"})
    assert_response(:success)
    assert(Movie.find_by(name: "Test Bare Create"))
  end
end
