require "test_helper"

# A join model (`Star`) whose `starrable` is a polymorphic `belongs_to` (a `Movie` or a `Genre`).
# This is the realistic "starred" pattern: a single index response mixes target types in the same
# `starrable` field. (A `has_many`/HABTM is never polymorphic itself — the polymorphism lives on the
# join model's `belongs_to`.)
class Api::Test::StarsControllerTest < ActionController::TestCase
  def setup
    @user = User.create!(login: "stars_user")
    @movie = Movie.create!(name: "Starred Test Movie", price: 5.0)
    @genre = Genre.create!(name: "Starred Test Genre")
    @movie_star = Star.create!(user: @user, starrable: @movie)
    @genre_star = Star.create!(user: @user, starrable: @genre)
  end

  def star_by_id(id)
    @response.parsed_body.find { |r| r["id"] == id }
  end

  # One response carries both a Movie- and a Genre-typed `starrable`, each with its type and label.
  def test_mixed_polymorphic_targets_serialize_with_type_in_one_response
    get(:index, as: :json)
    assert_response(:success)

    assert_equal(
      { "id" => @movie.id, "type" => "Movie", "name" => @movie.name },
      star_by_id(@movie_star.id)["starrable"],
    )
    assert_equal(
      { "id" => @genre.id, "type" => "Genre", "name" => @genre.name },
      star_by_id(@genre_star.id)["starrable"],
    )
  end

  # A regular `belongs_to` alongside the polymorphic one still serializes normally.
  def test_regular_belongs_to_still_serializes
    get(:index, as: :json)
    assert_response(:success)

    assert_equal({ "id" => @user.id, "login" => @user.login }, star_by_id(@movie_star.id)["user"])
  end

  # Filtering/ordering through the polymorphic association must be ignored, not raise.
  def test_filtering_and_ordering_through_polymorphic_association_does_not_error
    [
      { "starrable" => @movie.id.to_s },
      { "starrable.name" => @movie.name },
      { "starrable.name_cont" => "Test" },
      { "ordering" => "starrable.name" },
      { "ordering" => "-starrable.name" },
    ].each do |params|
      get(:index, as: :json, params: params)
      assert_response(:success, "params #{params.inspect} should not error")
    end
  end
end
