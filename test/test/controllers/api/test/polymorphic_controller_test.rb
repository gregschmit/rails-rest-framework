require "test_helper"

# Serialization and filter/order behavior for a polymorphic `belongs_to` (`User#favorite`, a `Movie`
# or a `Genre`). The `type` must always be serialized alongside the id. Filtering/ordering *through*
# the association (e.g. `favorite.name`, which needs a JOIN) is ignored rather than raising, but its
# backing `favorite_id`/`favorite_type` columns are filterable/orderable via `favorite.id`/
# `favorite.type` — they live on the base table, so no JOIN is needed.
class Api::Test::PolymorphicControllerTest < ActionController::TestCase
  def setup
    @movie = Movie.create!(name: "Polymorphic Test Movie", price: 9.99)
    @genre = Genre.create!(name: "Polymorphic Test Genre")
    @movie_fan = User.create!(login: "poly_movie_fan", favorite: @movie)
    @genre_fan = User.create!(login: "poly_genre_fan", favorite: @genre)
    @no_fan = User.create!(login: "poly_no_fan")
  end

  # The (unpaginated) index is a bare array; look up a serialized user by login.
  def user_by_login(login)
    @response.parsed_body.find { |r| r["login"] == login }
  end

  def test_polymorphic_association_serializes_id_type_and_label
    get(:index, as: :json)
    assert_response(:success)

    assert_equal(
      { "id" => @movie.id, "type" => "Movie", "name" => @movie.name },
      user_by_login("poly_movie_fan")["favorite"],
    )
    assert_equal(
      { "id" => @genre.id, "type" => "Genre", "name" => @genre.name },
      user_by_login("poly_genre_fan")["favorite"],
    )
  end

  def test_type_is_always_present_alongside_id
    get(:index, as: :json)
    assert_response(:success)

    %w[poly_movie_fan poly_genre_fan].each do |login|
      favorite = user_by_login(login)["favorite"]
      assert_includes(favorite.keys, "id")
      assert_includes(favorite.keys, "type")
    end
  end

  def test_missing_polymorphic_target_serializes_as_nil
    get(:index, as: :json)
    assert_response(:success)

    assert_nil(user_by_login("poly_no_fan")["favorite"])
  end

  # The polymorphic `*_type`/`*_id` columns are part of the association, so they must not leak as
  # top-level fields (like every foreign key).
  def test_polymorphic_backing_columns_are_not_top_level_fields
    fields = RESTFramework::Utils.fields_for(
      User, exclude_associations: false, action_text: false, active_storage: false
    )

    assert_includes(fields, "favorite")
    assert_not_includes(fields, "favorite_id")
    assert_not_includes(fields, "favorite_type")
  end

  # A polymorphic association can't be JOINed, so filtering/ordering through it must be ignored, not
  # raise `ActiveRecord::EagerLoadPolymorphicError`.
  def test_filtering_and_ordering_through_polymorphic_association_does_not_error
    [
      { "favorite" => @movie.id.to_s },
      { "favorite.name" => @movie.name },
      { "favorite.name_cont" => "Test" },
      { "ordering" => "favorite.name" },
      { "ordering" => "-favorite.name" },
    ].each do |params|
      get(:index, as: :json, params: params)
      assert_response(:success, "params #{params.inspect} should not error")
    end
  end

  def test_filtering_through_polymorphic_association_is_ignored
    get(:index, as: :json, params: { "favorite.name" => "No Such Favorite" })
    assert_response(:success)

    # The unfilterable predicate is dropped, so both fans are still returned.
    assert(user_by_login("poly_movie_fan"), "movie fan should not be filtered out")
    assert(user_by_login("poly_genre_fan"), "genre fan should not be filtered out")
  end

  # The backing `favorite_type` column is filterable via the dotted `favorite.type` path.
  def test_filtering_by_polymorphic_type
    get(:index, as: :json, params: { "favorite.type" => "Genre" })
    assert_response(:success)

    ids = @response.parsed_body.map { |r| r["id"] }
    assert_equal(User.where(favorite_type: "Genre").order(:id).pluck(:id), ids.sort)
    assert(user_by_login("poly_genre_fan"), "genre fan should be included")
    assert_nil(user_by_login("poly_movie_fan"), "movie fan should be filtered out")
    assert_nil(user_by_login("poly_no_fan"), "user without a favorite should be filtered out")
  end

  # `favorite.type` + `favorite.id` together pin down a specific polymorphic target.
  def test_filtering_by_polymorphic_type_and_id
    get(:index, as: :json, params: { "favorite.type" => "Movie", "favorite.id" => @movie.id })
    assert_response(:success)

    ids = @response.parsed_body.map { |r| r["id"] }
    assert_equal(
      User.where(favorite_type: "Movie", favorite_id: @movie.id).order(:id).pluck(:id),
      ids.sort,
    )
    assert(user_by_login("poly_movie_fan"), "movie fan should be included")
    assert_nil(user_by_login("poly_genre_fan"), "genre fan should be filtered out")
  end

  # Predicates apply to the backing column too (`favorite.type_in=Genre,Movie`).
  def test_filtering_by_polymorphic_type_predicate
    get(:index, as: :json, params: { "favorite.type_in" => "Genre,Movie" })
    assert_response(:success)

    ids = @response.parsed_body.map { |r| r["id"] }
    assert_equal(User.where(favorite_type: [ "Genre", "Movie" ]).order(:id).pluck(:id), ids.sort)
    assert_nil(user_by_login("poly_no_fan"), "user without a favorite should be filtered out")
  end

  # The backing `favorite_type` column is orderable via the dotted `favorite.type` path. Restrict to
  # users with a favorite so the ordering is over non-null types and the assertion stays portable
  # across databases (which disagree on where NULLs sort).
  def test_ordering_by_polymorphic_type
    get(
      :index,
      as: :json,
      params: { "favorite.type_in" => "Genre,Movie", "ordering" => "favorite.type" },
    )
    assert_response(:success)

    types = @response.parsed_body.map { |r| r.dig("favorite", "type") }
    assert_includes(types, "Genre")
    assert_includes(types, "Movie")
    assert_equal(types.sort, types, "records were not ordered by favorite type ascending")
  end

  def test_ordering_by_polymorphic_type_descending
    get(
      :index,
      as: :json,
      params: { "favorite.type_in" => "Genre,Movie", "ordering" => "-favorite.type" },
    )
    assert_response(:success)

    types = @response.parsed_body.map { |r| r.dig("favorite", "type") }
    assert_equal(types.sort.reverse, types, "records were not ordered by favorite type descending")
  end
end
