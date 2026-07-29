require "test_helper"

class Api::Test::UsersControllerTest < ActionController::TestCase
  # A client-supplied page size is capped at the (default) `max_page_size`, so a huge value cannot
  # force an unbounded response. See security review #3.
  def test_page_size_is_capped_at_max_page_size
    max = self.class.controller_class.max_page_size
    assert(max, "expected a default max_page_size to be configured")

    get(:index, as: :json, params: { page_size: max + 1_000_000 })
    assert_response(:success)
    assert_equal(max, @response.parsed_body["page_size"])
  end

  # Test bulk update with a nonexistent record ID.
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
  def test_bulk_destroy_missing_record
    user = User.create!(login: "bulk_destroy_test", state: "default", status: "")
    fake_id = User.maximum(:id) + 9999

    delete(:destroy_all, as: :json, params: { _json: [ user.id, fake_id ] })
    assert_response(400)
    assert_match(/Missing/, @response.parsed_body["message"])
    # Transactional: user should still exist since destroy rolled back.
    assert(User.find_by(id: user.id))
  end

  # Test bulk update with no _json body (triggers "Expected an array of objects").
  def test_bulk_update_no_json
    patch(:update_all, as: :json, params: { login: "bad" })
    assert_response(400)
    assert_match(/Expected an array of objects/, @response.parsed_body["message"])
  end

  # Test bulk destroy with no _json body (triggers "Expected an array of primary keys").
  def test_bulk_destroy_no_json
    delete(:destroy_all, as: :json, params: { login: "bad" })
    assert_response(400)
    assert_match(/Expected an array of primary keys/, @response.parsed_body["message"])
  end

  # Test bulk update with objects missing the primary key.
  def test_bulk_update_nil_pk
    patch(
      :update_all,
      as: :json,
      params: { _json: [ { login: "no_pk_1" }, { login: "no_pk_2" } ] },
    )
    assert_response(400)
    assert_match(/primary key/, @response.parsed_body["message"])
  end

  # Test create with association data submitted by association name (not _id).
  def test_create_with_association_by_name
    manager = User.create!(login: "mgr_dispatch_test", state: "default", status: "")
    post(:create, as: :json, params: { login: "assoc_dispatch_test", manager: manager.id })
    assert_response(:success)
  end

  def test_create_with_nested_association
    post(
      :create,
      as: :json,
      params: {
        login: "nested_dispatch_test",
        manager: { login: "nested_mgr", state: "default", status: "" },
      },
    )
    assert_response(:success)
  end
end
