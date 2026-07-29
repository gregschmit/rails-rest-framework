require "test_helper"

# Migrated from the removed plain API: with `paginator_class = nil`, the index action skips
# pagination and returns a bare array (not a `{ results: ... }` envelope), and filtering still works.
class Api::Test::UnpaginatedControllerTest < ActionController::TestCase
  def test_index_skips_pagination_and_returns_a_bare_array
    get(:index, as: :json)
    assert_response(:success)
    assert_kind_of(Array, @response.parsed_body)
  end

  def test_filtering_on_the_unpaginated_path
    user = User.first
    get(:index, as: :json, params: { login: user.login })
    assert_response(:success)

    body = @response.parsed_body
    assert_kind_of(Array, body)
    assert(body.any? { |r| r["id"] == user.id })
    assert(body.all? { |r| r["login"] == user.login })
  end
end
