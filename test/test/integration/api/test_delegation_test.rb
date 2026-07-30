require "test_helper"

# Actions declared with `metadata: { delegate: true }` dispatch through the single `rrf_delegate`
# action to the model class (collection) or the record (member). `Api::Test::UsersController`
# declares a same-named `status_keys` on both scopes, so this also covers scope disambiguation. The
# delegated method's return value is rendered under a `return` key.
class Api::TestDelegationTest < ActionDispatch::IntegrationTest
  def test_collection_action_delegates_to_the_model_class_method
    get("/api/test/users/status_keys.json")

    assert_response(:success)
    assert_equal(User.status_keys.map(&:to_s), response.parsed_body["return"])
  end

  def test_member_action_delegates_to_the_record_method
    user = User.create!(login: "delegation_test", state: "default", status: "")
    get("/api/test/users/#{user.id}/status_keys.json")

    assert_response(:success)
    assert_equal(user.status_keys.map(&:to_s), response.parsed_body["return"])
  end

  def test_singular_controller_delegates_to_the_record
    # `Api::Test::UserController` is singular and declares `delegated` with bare `add_action`, which
    # makes it a member action — so delegation targets the record, not the model class.
    get("/api/test/user/delegated.json")

    assert_response(:success)
    record = User.first!
    assert_equal(
      { "login" => record.login, "is_admin" => record.is_admin }, response.parsed_body["return"]
    )
  end

  def test_delegation_passes_query_params_as_kwargs
    user = User.create!(login: "delegation_kwargs", state: "default", status: "")
    get("/api/test/users/#{user.id}/echo_kwargs.json?a=1&b=2")

    assert_response(:success)
    assert_equal({ "a" => "1", "b" => "2" }, response.parsed_body["return"])
  end

  def test_delegation_detects_keyrest_after_a_trailing_block
    # `echo_kwargs_with_block` is `(**opts, &block)`, so the `:keyrest` isn't the last parameter;
    # scanning all params (not just the last) must still pass the kwargs through.
    user = User.create!(login: "delegation_block", state: "default", status: "")
    get("/api/test/users/#{user.id}/echo_kwargs_with_block.json?a=1")

    assert_response(:success)
    assert_equal({ "a" => "1" }, response.parsed_body["return"])
  end

  def test_delegation_passes_scalar_args_param_as_a_single_positional
    user = User.create!(login: "delegation_scalar", state: "default", status: "")
    get("/api/test/users/#{user.id}/echo_positional.json?args=hello")

    assert_response(:success)
    assert_equal([ "hello", nil ], response.parsed_body["return"])
  end

  def test_delegation_splats_array_args_param_as_positionals
    user = User.create!(login: "delegation_array", state: "default", status: "")
    get("/api/test/users/#{user.id}/echo_positional.json?args[]=one&args[]=two")

    assert_response(:success)
    assert_equal([ "one", "two" ], response.parsed_body["return"])
  end

  def test_delegation_wraps_a_nil_return_instead_of_erroring
    # A bare `nil` return would trip `render_api`'s nil guard; wrapping under `return` keeps it a
    # clean success.
    user = User.create!(login: "delegation_nil", state: "default", status: "")
    get("/api/test/users/#{user.id}/returns_nil.json")

    assert_response(:success)
    assert_nil(response.parsed_body["return"])
  end

  def test_delegation_serializes_active_record_returns_through_the_serializer
    # `self_record` returns the record itself; the framework serializer must be applied (honoring
    # the controller's `only` config) rather than leaking every column via raw `as_json`.
    user = User.create!(login: "delegation_ar", state: "default", status: "")
    get("/api/test/users/#{user.id}/self_record.json")

    assert_response(:success)
    returned = response.parsed_body["return"]
    assert_equal(user.login, returned["login"])
    # `status`/`age` aren't in `UsersSerializer`'s singular `only` config, so they must be excluded.
    refute(returned.key?("status"))
    refute(returned.key?("age"))
  end

  def test_delegation_to_a_private_method_is_not_found
    # `secret` is private, so delegation must resolve to a clean 404 rather than reaching it.
    user = User.create!(login: "delegation_private", state: "default", status: "")
    get("/api/test/users/#{user.id}/secret.json")

    assert_response(404)
  end
end
