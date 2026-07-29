require "test_helper"

# Actions declared with `metadata: { delegate: true }` dispatch through the single `rrf_delegate`
# action to the model class (collection) or the record (member). `Api::Test::UsersController`
# declares a same-named `status_keys` on both scopes, so this also covers scope disambiguation.
class Api::TestDelegationTest < ActionDispatch::IntegrationTest
  def test_collection_action_delegates_to_the_model_class_method
    get("/api/test/users/status_keys.json")

    assert_response(:success)
    assert_equal(User.status_keys.map(&:to_s), response.parsed_body)
  end

  def test_member_action_delegates_to_the_record_method
    user = User.create!(login: "delegation_test", state: "default", status: "")
    get("/api/test/users/#{user.id}/status_keys.json")

    assert_response(:success)
    assert_equal(user.status_keys.map(&:to_s), response.parsed_body)
  end
end
