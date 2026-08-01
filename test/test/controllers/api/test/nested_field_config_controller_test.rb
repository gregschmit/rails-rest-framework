require "test_helper"

class Api::Test::NestedFieldConfigControllerTest < ActionController::TestCase
  # A nested `field_config` shapes an association more than one level deep: `movies` is restricted
  # to its configured fields, and `genres` to `id`/`name` (dropping `description`).
  def test_nested_field_config_shapes_sub_association
    genre = Genre.create!(name: "Nested Genre", description: "should not serialize")
    movie = Movie.create!(name: "Nested Movie", price: 9.99, genres: [ genre ])
    user = User.create!(login: "nested_fc_user", state: "default", status: "")
    user.movies << movie

    get(:show, as: :json, params: { id: user.id })
    assert_response(:success)

    movie_json = @response.parsed_body["movies"].first
    # `price` isn't in the movie `fields`, so it's dropped.
    assert_equal([ "genres", "id", "name" ], movie_json.keys.sort)

    genre_json = movie_json["genres"].first
    assert_equal({ "id" => genre.id, "name" => "Nested Genre" }, genre_json)
    refute(genre_json.key?("description"))
  end
end
