require "test_helper"

# Two nested-resource patterns in the demo API:
# - `/movies/:movie_id/genres` reuses the top-level `Api::Demo::GenresController` (no dedicated
#   controller) and is auto-scoped to the movie's genres via `scope_nested_by_parent`.
# - `/users/:user_id/movies` targets a dedicated `Api::Demo::Users::MoviesController`, reached by a
#   `scope(module: :users)` since `rest_resources` resolves the controller in the current scope.
class Api::DemoNestedResourcesTest < ActionDispatch::IntegrationTest
  def records
    body = response.parsed_body
    body.is_a?(Array) ? body : body["results"]
  end

  def test_reused_controller_is_auto_scoped_to_the_parent
    mine = Genre.create!(name: "auto_scope_mine")
    other = Genre.create!(name: "auto_scope_other")
    movie = Movie.create!(name: "auto_scope_movie", genres: [ mine ])

    get("/api/demo/movies/#{movie.id}/genres.json")
    assert_response(:success)
    names = records.map { |g| g["name"] }
    assert_includes(names, "auto_scope_mine")
    assert_not_includes(names, "auto_scope_other")
  end

  def test_reused_controller_404s_for_a_missing_parent
    get("/api/demo/movies/0/genres.json")
    assert_response(404)
  end

  # `/movies/:movie_id/genres/:genre_id/movies` scopes along the whole chain:
  # `Movie.find(movie_id).genres.find(genre_id).movies`.
  def test_two_level_chain_is_scoped_end_to_end
    genre = Genre.create!(name: "chain_genre")
    outer = Movie.create!(name: "chain_outer", genres: [ genre ])
    sibling = Movie.create!(name: "chain_sibling", genres: [ genre ])

    get("/api/demo/movies/#{outer.id}/genres/#{genre.id}/movies.json")
    assert_response(:success)
    names = records.map { |m| m["name"] }
    # The innermost collection is the genre's movies.
    assert_includes(names, "chain_outer")
    assert_includes(names, "chain_sibling")
  end

  def test_two_level_chain_enforces_the_intermediate_link
    genre = Genre.create!(name: "chain_genre_2")
    unrelated = Movie.create!(name: "chain_unrelated")  # does not have `genre`

    # `genre` isn't one of `unrelated`'s genres, so the middle `find` 404s.
    get("/api/demo/movies/#{unrelated.id}/genres/#{genre.id}/movies.json")
    assert_response(404)
  end

  def test_dedicated_nested_controller_is_routed
    # The nested route resolves to the dedicated, namespaced controller — not top-level movies.
    assert_recognizes(
      { controller: "api/demo/users/movies", action: "index", user_id: "5", format: "json" },
      "/api/demo/users/5/movies.json",
    )

    mine = Movie.create!(name: "dedicated_mine")
    other = Movie.create!(name: "dedicated_other")
    user = User.create!(login: "dedicated_user", state: "default", status: "")
    user.movies << mine

    get("/api/demo/users/#{user.id}/movies.json")
    assert_response(:success)
    names = records.map { |m| m["name"] }
    assert_includes(names, "dedicated_mine")
    assert_not_includes(names, "dedicated_other")
  end
end
