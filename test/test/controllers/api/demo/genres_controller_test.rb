require_relative "base"

class Api::Demo::GenresControllerTest < ActionController::TestCase
  include Api::Demo::Base

  self.create_params = { name: "mutation_test" }
  self.update_params = { name: "mutation_test" }

  # Genre table has no `created_at` column, so skip the base test.
  def test_cannot_create_with_specific_created_at
    assert(true)
  end

  # --- Bulk raw mode ---

  def test_bulk_create_raw
    post(
      :create,
      as: :json,
      params: { _json: [ { name: "test_raw_1" }, { name: "test_raw_2" } ] },
    )
    assert_response(:success)
    assert(Genre.find_by(name: "test_raw_1"))
    assert(Genre.find_by(name: "test_raw_2"))
  end

  # A client must not be able to set the primary key on a (raw) bulk create: the pk is read-only and
  # stripped from each element, so a conflicting `id` is ignored and a fresh record is created
  # rather than colliding with an existing one. See security review #1.
  def test_bulk_create_raw_ignores_client_supplied_primary_key
    existing = Genre.first
    post(
      :create,
      as: :json,
      params: { _json: [ { id: existing.id, name: "test_raw_pk" } ] },
    )
    assert_response(:success)
    created = Genre.find_by(name: "test_raw_pk")
    assert(created, "a new genre should have been created")
    assert_not_equal(existing.id, created.id, "client-supplied primary key must be ignored")
    assert_equal(existing.name, existing.reload.name) # Pre-existing record untouched.
  end

  def test_bulk_create_raw_requires_uniform_keys
    post(
      :create,
      as: :json,
      params: { _json: [ { name: "test_1" }, { name: "test_2", description: "desc" } ] },
    )
    assert_response(400)
    assert_match(/same attrs/, @response.parsed_body["message"])
    assert_nil(Genre.find_by(name: "test_1"))
  end

  def test_bulk_create_raw_with_error
    Genre.create!(name: "test_raw_dup")
    post(
      :create,
      as: :json,
      params: { _json: [ { name: "test_raw_dup" }, { name: "test_raw_new" } ] },
    )
    # Raw insert_all with unique constraint violation.
    assert_response(400)
  end

  def test_bulk_update_raw
    genre1 = Genre.create!(name: "test_raw_update_1")
    genre2 = Genre.create!(name: "test_raw_update_2")
    old_count = Genre.count

    patch(
      :update_all,
      as: :json,
      params: {
        _json: [
          { id: genre1.id, name: "test_raw_updated_1" },
          { id: genre2.id, name: "test_raw_updated_2" },
        ],
      },
    )
    assert_response(:success)

    genre1.reload
    genre2.reload
    assert_equal("test_raw_updated_1", genre1.name)
    assert_equal("test_raw_updated_2", genre2.name)
    assert_equal(old_count, Genre.count)
  end

  def test_bulk_destroy_raw
    genre_names = [ "Test Raw Destroy 1", "Test Raw Destroy 2" ]
    genre_names.each { |n| Genre.create!(name: n) }
    genres = Genre.where(name: genre_names)
    assert_equal(2, genres.count)
    delete(:destroy_all, as: :json, params: { _json: genres.pluck(:id) })
    assert_response(:success)
    assert_equal(0, genres.count)
  end
end
