require "test_helper"

class Api::Test::FindByControllerTest < ActionController::TestCase
  # Test showing a record by find_by (non-primary-key) field.
  # Covers controller.rb lines 799-803, 812, 819.
  def test_show_by_login
    user = User.create!(login: "find_by_test_user", state: "default", status: "")
    get(:show, as: :json, params: { id: user.login, find_by: "login" })
    assert_response(:success)
    assert_equal(user.login, @response.parsed_body["login"])
  end

  def test_show_by_login_not_found
    get(:show, as: :json, params: { id: "nonexistent_login", find_by: "login" })
    assert_response(404)
  end
end
