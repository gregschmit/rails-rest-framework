require "test_helper"

# A polymorphic `belongs_to` (`User#favorite`, a `Movie` or a `Genre`) with extra configured fields.
# Each field is resolved against the actual target, so a field that only exists on one target class
# (`price` on `Movie`, not `Genre`) is serialized there and omitted elsewhere.
class Api::Test::PolymorphicFieldsControllerTest < ActionController::TestCase
  def setup
    @movie = Movie.create!(name: "Poly Fields Movie", price: 12.50)
    @priceless_movie = Movie.create!(name: "Poly Fields Priceless Movie", price: nil)
    @genre = Genre.create!(name: "Poly Fields Genre")
    @movie_fan = User.create!(login: "poly_fields_movie_fan", favorite: @movie)
    @priceless_fan = User.create!(login: "poly_fields_priceless_fan", favorite: @priceless_movie)
    @genre_fan = User.create!(login: "poly_fields_genre_fan", favorite: @genre)
  end

  def user_by_login(login)
    @response.parsed_body.find { |r| r["login"] == login }
  end

  # A `Movie` target responds to `price`, so the configured field is serialized. `as_json` matches
  # how the framework's JSON encoder renders the decimal, avoiding a brittle format assumption.
  def test_movie_target_serializes_all_configured_fields
    get(:index, as: :json)
    assert_response(:success)

    expected = {
      "id" => @movie.id,
      "type" => "Movie",
      "name" => @movie.name,
      "price" => @movie.as_json["price"],
    }
    assert_equal(expected, user_by_login("poly_fields_movie_fan")["favorite"])
  end

  # A `Genre` target has no `price`, so that field is omitted rather than serialized as nil.
  def test_genre_target_omits_field_absent_on_that_target
    get(:index, as: :json)
    assert_response(:success)

    favorite = user_by_login("poly_fields_genre_fan")["favorite"]
    assert_equal({ "id" => @genre.id, "type" => "Genre", "name" => @genre.name }, favorite)
    assert_not(favorite.key?("price"), "price is not a Genre field and must be omitted")
  end

  # A `Movie` with a null price still has the `price` field (it exists on the class), serialized as
  # nil. This is the key distinction from `Genre`, where the field does not exist and is omitted.
  def test_field_present_but_null_serializes_as_nil
    get(:index, as: :json)
    assert_response(:success)

    favorite = user_by_login("poly_fields_priceless_fan")["favorite"]
    assert(favorite.key?("price"), "price exists on Movie, so the key must be present")
    assert_nil(favorite["price"])
  end
end
