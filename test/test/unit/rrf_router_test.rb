require "test_helper"

# Tests for the router argument guards: `rest_resources` routes several controllers sharing options,
# so per-name options (`path:`/`as:`/`controller:`) and a block only make sense with a single name;
# `rest_resource` routes a single controller. Happy-path routing is covered by the integration
# route-set (routing the test app), so these focus on the guards.
class RRFRouterTest < Minitest::Test
  def draw(&block)
    ActionDispatch::Routing::RouteSet.new.draw(&block)
  end

  def test_multiple_names_with_a_per_name_option_raise
    [ { path: "films" }, { as: "films" }, { controller: "movies" } ].each do |opts|
      assert_raises(ArgumentError) { draw { rest_resources(:movies, :users, **opts) } }
    end
  end

  def test_multiple_names_with_a_block_raise
    assert_raises(ArgumentError) { draw { rest_resources(:movies, :users) { } } }
  end

  # `rest_resource` routes a single controller, so several names is an error.
  def test_rest_resource_rejects_multiple_names
    assert_raises(ArgumentError) { draw { rest_resource(:movies, :users) } }
  end
end
