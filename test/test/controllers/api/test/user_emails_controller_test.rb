require "test_helper"

class Api::Test::UserEmailsControllerTest < ActionController::TestCase
  def test_bulk_create_raw_inherits_recordset_scope
    user1 = User.create!(login: "scope_test_1", state: "default", status: "")
    user2 = User.create!(login: "scope_test_2", state: "default", status: "")

    # Try to create an email under user1's scope but supply user2's id.
    @request.env["QUERY_STRING"] = ""
    post(
      :create,
      as: :json,
      params: {
        user_id: user1.id,
        _json: [ { email: "scoped@example.com", user: user2.id } ],
      },
    )
    assert_response(:success)

    email = Email.find_by(email: "scoped@example.com")
    assert(email)
    # The recordset scope (user1) should win over the consumer-supplied user_id (user2).
    assert_equal(user1.id, email.user_id)
  end
end
