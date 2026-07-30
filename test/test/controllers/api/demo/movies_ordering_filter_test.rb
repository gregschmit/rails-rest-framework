require "test_helper"

# Security regression for the ordering filter's association sub-field allowlist.
#
# `Movie#main_genre` (a `Genre`) exposes only `id`/`name` as serializable association fields, while
# `Genre#description` is a real column that is NOT allowlisted. OrderingFilter used to validate only
# the *root* of a dotted `?ordering=main_genre.description` token, so — once a sibling QueryFilter
# dotted filter (`?main_genre.name_in=...`) forced a JOIN on the genres table — a client could
# `ORDER BY` the hidden column and use ascending/descending order plus pagination as an oracle to
# infer values of a column that is never serialized. The filter now drops dotted tokens whose
# sub-field is not an allowlisted sub_field, and joins the association for the ones that are.
class Api::Demo::MoviesOrderingFilterTest < ActionController::TestCase
  tests Api::Demo::MoviesController

  # Filtering by every genre name forces the JOIN (via QueryFilter) and includes every movie that
  # has a main_genre, maximizing the number of distinct genre descriptions in the result.
  def all_genre_names
    Genre.pluck(:name)
  end

  # The index response is a bare array when unpaginated (`page_size=0`) and a `results` hash
  # otherwise; normalize to the record array either way.
  def index_records
    body = @response.parsed_body
    body.is_a?(Array) ? body : body["results"]
  end

  def get_index(ordering, extra = {})
    get(
      :index,
      as: :json,
      params: {
        "main_genre.name_in" => all_genre_names.join(","),
        "ordering" => ordering,
        "page_size" => 0,
        **extra,
      },
    )
  end

  # Guard the assumptions the exploit depends on, so the test can't silently rot into a no-op if the
  # model or the association-fields defaults change.
  def test_hidden_association_subfield_precondition
    assert_includes(Genre.column_names, "description")
    association_fields = Api::Demo::MoviesController.field_configuration["main_genre"][:fields]
    assert_includes(association_fields, "name")
    assert_not_includes(association_fields, "description")
  end

  def test_ordering_by_non_allowlisted_association_subfield_is_ignored
    get_index("main_genre.description,main_genre.name")
    assert_response(:success)
    asc = index_records.map { |r| r["id"] }

    get_index("-main_genre.description,main_genre.name")
    assert_response(:success)
    desc = index_records.map { |r| r["id"] }

    # With the hidden column dropped, both requests collapse to the allowlisted `main_genre.name`
    # ordering and return identical results. If it had reached `ORDER BY`, ascending vs. descending
    # order would differ — that difference is exactly the oracle.
    assert_equal(
      asc,
      desc,
      "ordering by the non-allowlisted column `main_genre.description` changed result order",
    )
  end

  def test_hidden_association_column_is_never_serialized
    get_index("main_genre.description")
    assert_response(:success)

    main_genres = index_records.map { |r| r["main_genre"] }.compact
    assert(main_genres.any?, "expected at least one movie with a serialized main_genre")
    main_genres.each do |genre|
      assert_not(genre.key?("description"), "hidden Genre#description was serialized: #{genre}")
    end
  end

  def test_ordering_by_allowlisted_association_subfield_sorts_and_does_not_error
    # Previously this raised ActiveRecord::StatementInvalid (no JOIN was added) — an unhandled 500.
    get_index("main_genre.name")
    assert_response(:success)

    names = index_records.map { |r| r.dig("main_genre", "name") }.compact
    assert_operator(names.length, :>, 1)
    assert_equal(names.sort, names, "records were not ordered by the associated genre name")
  end
end
