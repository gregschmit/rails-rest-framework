require "test_helper"

# Phase 2: per-association record limits via `?associations.<name>.limit=N` (or `all`).
module Api::Test::AssocExp
  module ManagedUsersHelper
    def setup
      @manager = User.create!(login: "limit_mgr", state: "default", status: "")
      6.times do |i|
        User.create!(login: "limit_child_#{i}", state: "default", status: "", manager: @manager)
      end
    end

    def managed_count(params = {})
      get(:index, as: :json, params: params)
      assert_response(:success)
      records = @response.parsed_body
      records = records["results"] unless records.is_a?(Array)
      records.find { |r| r["login"] == "limit_mgr" }["managed_users"].length
    end
  end

  class LimitTest < ActionController::TestCase
    include ManagedUsersHelper
    tests Api::Test::AssocExp::LimitsController

    def test_default_limit_applies_without_a_request
      assert_equal(2, managed_count)
    end

    def test_requested_limit_within_the_cap
      assert_equal(4, managed_count("associations.managed_users.limit" => "4"))
    end

    def test_requested_limit_is_capped_at_the_max
      assert_equal(5, managed_count("associations.managed_users.limit" => "10"))
    end

    def test_all_yields_the_cap
      assert_equal(5, managed_count("associations.managed_users.limit" => "all"))
    end

    def test_none_and_zero_are_aliases_for_all
      assert_equal(5, managed_count("associations.managed_users.limit" => "none"))
      assert_equal(5, managed_count("associations.managed_users.limit" => "0"))
    end

    def test_non_integer_limit_is_ignored
      assert_equal(2, managed_count("associations.managed_users.limit" => "10junk"))
    end
  end

  # Per-association `nil` overrides: unlimited default, and unlimited `all` (uncapped).
  class UnlimitedPerAssociationTest < ActionController::TestCase
    include ManagedUsersHelper
    tests Api::Test::AssocExp::LimitsUnlimitedController

    def test_nil_limit_serializes_all_by_default
      assert_equal(6, managed_count)
    end

    def test_all_is_unlimited_when_the_cap_is_nil
      assert_equal(6, managed_count("associations.managed_users.limit" => "all"))
    end
  end

  class PerAssociationLimitTest < ActionController::TestCase
    include ManagedUsersHelper
    tests Api::Test::AssocExp::LimitsPerAssocController

    def test_per_association_default_overrides_the_controller_default
      assert_equal(1, managed_count)
    end

    def test_per_association_cap_overrides_the_controller_cap
      assert_equal(3, managed_count("associations.managed_users.limit" => "10"))
    end

    def test_all_yields_the_per_association_cap
      assert_equal(3, managed_count("associations.managed_users.limit" => "all"))
    end
  end

  class LimitFeatureDisabledTest < ActionController::TestCase
    include ManagedUsersHelper
    tests Api::Test::AssocExp::LimitsDisabledController

    def test_limit_param_is_ignored_but_default_still_bounds
      assert_equal(2, managed_count("associations.managed_users.limit" => "10"))
    end
  end
end
