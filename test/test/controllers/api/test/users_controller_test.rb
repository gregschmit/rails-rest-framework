require "test_helper"

class Api::Test::UsersControllerTest < ActionController::TestCase
  # Test bulk update with a nonexistent record ID.
  # Covers controller/bulk.rb lines 190, 196-197.
  def test_bulk_update_missing_record
    user = User.create!(login: "bulk_update_test", state: "default", status: "")
    fake_id = User.maximum(:id) + 9999

    patch(
      :update_all,
      as: :json,
      params: { _json: [ { id: user.id, login: "updated" }, { id: fake_id, login: "ghost" } ] },
    )
    assert_response(400)
    assert_match(/not found/, @response.parsed_body["message"])
  end

  # Test bulk destroy with a nonexistent record ID (transactional mode).
  # Covers controller/bulk.rb lines 252-254.
  def test_bulk_destroy_missing_record
    user = User.create!(login: "bulk_destroy_test", state: "default", status: "")
    fake_id = User.maximum(:id) + 9999

    delete(:destroy_all, as: :json, params: { _json: [ user.id, fake_id ] })
    assert_response(400)
    assert_match(/Missing/, @response.parsed_body["message"])
    # Transactional: user should still exist since destroy rolled back.
    assert(User.find_by(id: user.id))
  end
end
