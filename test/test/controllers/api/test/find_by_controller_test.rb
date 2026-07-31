require "test_helper"

class Api::Test::FindByControllerTest < ActionController::TestCase
  # Test showing a record by find_by (non-primary-key) field.
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

  def test_show_by_virtual_field_is_not_allowed_by_default
    get(:show, as: :json, params: { id: "5.45", find_by: "calculated_property" })
    assert_response(404)
  end

  # A real column that isn't a serialized field must not be a lookup key, or it becomes a
  # record-enumeration surface (e.g. `?find_by=reset_password_token`).
  def test_show_by_non_serialized_column_is_not_allowed
    user = User.create!(login: "find_by_non_serialized", state: "default", status: "busy")
    get(:show, as: :json, params: { id: user.status, find_by: "status" })
    assert_response(404)
  end

  # A write_only real column is never serialized, so it must not be a lookup key either.
  def test_show_by_write_only_column_is_not_allowed
    user = User.create!(
      login: "find_by_write_only", state: "default", status: "", legal_name: "Secret Legal Name",
    )
    get(:show, as: :json, params: { id: user.legal_name, find_by: "legal_name" })
    assert_response(404)
  end
end
