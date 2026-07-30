require "test_helper"

# Consumer-driven association expansion (Phase 1: `fields`). A consumer may request extra fields for
# a serialized association via `?associations.<name>.fields=…`, bounded by an allowlist so an
# association can never expose more than its own endpoint would.
module Api::Test::AssocExp
  module ManagerHelper
    def setup
      @manager = User.create!(
        login: "assoc_mgr", state: "default", status: "", age: 44, balance: 99.5, is_admin: true,
      )
      @child = User.create!(
        login: "assoc_child", state: "default", status: "", manager: @manager,
      )
    end

    # The serialized `manager` for our test child user, from the (unpaginated) index array.
    def manager_for_child
      records = @response.parsed_body
      records = records["results"] unless records.is_a?(Array)
      entry = records.find { |r| r["login"] == "assoc_child" }
      entry && entry["manager"]
    end
  end

  # Sibling-discovery path: the sibling for `manager` (a `User`) is this controller itself.
  class SiblingDiscoveryTest < ActionController::TestCase
    include ManagerHelper
    tests Api::Test::AssocExp::UsersController

    def test_default_association_fields_when_not_requested
      get(:index, as: :json)
      assert_response(:success)
      assert_equal(%w[id login], manager_for_child.keys.sort)
    end

    def test_requested_allowed_fields_are_expanded
      get(:index, as: :json, params: { "associations.manager.fields" => "age,balance,is_admin" })
      assert_response(:success)
      manager = manager_for_child

      assert_includes(manager.keys, "id", "primary key is always kept")
      assert_includes(manager.keys, "age", "an allowed field is expanded")
      assert_includes(manager.keys, "balance", "a hidden field is requestable")
      assert_equal(44, manager["age"])
      # Replace-semantics: an unrequested default field is dropped.
      refute_includes(manager.keys, "login")
      # Anti-leak: a write_only field can never be pulled in.
      refute_includes(manager.keys, "is_admin")
    end

    def test_write_only_field_is_never_leaked
      get(:index, as: :json, params: { "associations.manager.fields" => "is_admin" })
      assert_response(:success)
      # Only the primary key survives; the write_only field is dropped.
      assert_equal(%w[id], manager_for_child.keys)
    end
  end

  # Explicit-allowlist path: `requestable_fields` takes priority over the (still-discoverable)
  # sibling, which would otherwise allow `balance`.
  class ExplicitAllowlistTest < ActionController::TestCase
    include ManagerHelper
    tests Api::Test::AssocExp::UsersExplicitController

    def test_only_requestable_fields_are_expanded
      get(:index, as: :json, params: { "associations.manager.fields" => "age,balance" })
      assert_response(:success)
      manager = manager_for_child

      assert_includes(manager.keys, "age", "a field in requestable_fields is expanded")
      refute_includes(manager.keys, "balance", "the sibling allows balance, but explicit wins")
    end
  end

  # Secure-by-default: the feature is off, so the query param is ignored.
  class DisabledByDefaultTest < ActionController::TestCase
    include ManagerHelper
    tests Api::Test::AssocExp::UsersDisabledController

    def test_association_query_params_are_ignored
      get(:index, as: :json, params: { "associations.manager.fields" => "age" })
      assert_response(:success)
      assert_equal(%w[id login], manager_for_child.keys.sort)
    end
  end

  # When the sibling serializes through a custom serializer we can't introspect, its `get_fields`
  # must not be trusted for the allowlist — so no expansion happens via that path.
  class CustomSerializerSiblingTest < ActionController::TestCase
    tests Api::Test::AssocExp::MoviesController

    def setup
      @genre = Genre.create!(name: "assoc_genre", description: "secret-ish")
      @movie = Movie.create!(name: "assoc_movie", main_genre: @genre)
    end

    def test_expansion_is_refused_when_sibling_uses_a_custom_serializer
      get(:index, as: :json, params: { "associations.main_genre.fields" => "description" })
      assert_response(:success)

      records = @response.parsed_body
      records = records["results"] unless records.is_a?(Array)
      genre = records.find { |r| r["name"] == "assoc_movie" }["main_genre"]

      # `description` isn't allowed, so replace-semantics leaves just the primary key.
      refute_includes(genre.keys, "description")
      assert_equal(%w[id], genre.keys)
    end
  end
end
