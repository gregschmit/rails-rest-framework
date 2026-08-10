require "test_helper"

# A JSON/JSONB column accepts any JSON value, so `create`/`update` must permit scalars, arrays, and
# hashes (and nested combinations) — strong params can't express all three for one key, so the
# framework permits hashes natively and re-injects scalar/array values after filtering.
class Api::Test::JsonColumnControllerTest < ActionController::TestCase
  def create_with(preferences)
    login = "json_col_#{rand(1_000_000)}"
    post(:create, as: :json, params: { login: login, preferences: preferences })
  end

  def test_create_with_scalar_string
    create_with("dark")
    assert_response(:created)
    assert_equal("dark", @response.parsed_body["preferences"])
  end

  def test_create_with_scalar_number
    create_with(42)
    assert_response(:created)
    assert_equal(42, @response.parsed_body["preferences"])
  end

  def test_create_with_array_of_scalars
    create_with([ "a", "b", "c" ])
    assert_response(:created)
    assert_equal([ "a", "b", "c" ], @response.parsed_body["preferences"])
  end

  def test_create_with_array_of_hashes
    create_with([ { "k" => 1 }, { "k" => 2 } ])
    assert_response(:created)
    assert_equal([ { "k" => 1 }, { "k" => 2 } ], @response.parsed_body["preferences"])
  end

  def test_create_with_hash
    create_with({ "theme" => "dark", "nested" => { "size" => 3 }, "tags" => [ "x", "y" ] })
    assert_response(:created)
    assert_equal(
      { "theme" => "dark", "nested" => { "size" => 3 }, "tags" => [ "x", "y" ] },
      @response.parsed_body["preferences"],
    )
  end

  def test_update_replaces_value
    user = User.create!(login: "json_col_update", preferences: { "old" => true })
    patch(:update, as: :json, params: { id: user.id, preferences: [ 1, 2, 3 ] })
    assert_response(:success)
    assert_equal([ 1, 2, 3 ], user.reload.preferences)
  end
end
