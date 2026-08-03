require "test_helper"

# `/api/test/nested/movies/:movie_id/genres` reuses the top-level scoping of the parent controller:
# auto-scoping looks the parent movie up through `Api::Test::Nested::MoviesController#get_recordset`
# (found by model, like association fields), so a movie outside that recordset is unreachable.
class Api::TestNestedParentScopeTest < ActionDispatch::IntegrationTest
  def test_parent_controllers_access_scope_is_enforced
    genre = Genre.create!(name: "nested_scope_genre")
    visible = Movie.create!(name: "nested_visible", genres: [ genre ])
    hidden = Movie.create!(name: "nested_hidden", genres: [ genre ])

    # `visible` is within the parent controller's recordset — its genres are reachable.
    get("/api/test/nested/movies/#{visible.id}/genres.json")
    assert_response(:success)
    assert_equal([ "nested_scope_genre" ], response.parsed_body.map { |g| g["name"] })

    # `hidden` is excluded by the parent controller's `get_recordset`, so the nested route 404s
    # (existence-hiding) even though the movie and its genre both exist.
    get("/api/test/nested/movies/#{hidden.id}/genres.json")
    assert_response(404)
  end
end
