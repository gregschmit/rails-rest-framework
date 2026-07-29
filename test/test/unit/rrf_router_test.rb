require "test_helper"

# Tests for the `rest_route` splat guard: per-name options (`path:`/`as:`/`controller:`) and a block
# only make sense with a single name. Happy-path splat routing is covered by the integration
# route-set (routing the test app), so these focus on the argument guard.
class RRFRouterTest < Minitest::Test
  def draw(&block)
    ActionDispatch::Routing::RouteSet.new.draw(&block)
  end

  def test_multiple_names_with_a_per_name_option_raise
    [ { path: "films" }, { as: "films" }, { controller: "movies" } ].each do |opts|
      assert_raises(ArgumentError) { draw { rest_route(:movies, :users, **opts) } }
    end
  end

  def test_multiple_names_with_a_block_raise
    assert_raises(ArgumentError) { draw { rest_route(:movies, :users) { } } }
  end
end
