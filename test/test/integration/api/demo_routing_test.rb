require "test_helper"

# The goal of this test is to ensure that the proper routes are defined for the demo API.
class Api::DemoRoutingTest < ActionDispatch::IntegrationTest
  def test_can_get_root
    get("/api/demo")
    assert_response(:success)
    get("/api/demo.json")
    assert_response(:success)
  end

  def test_can_get_users
    get("/api/demo/users")
    assert_response(:success)
    get("/api/demo/users.json")
    assert_response(:success)
  end

  def test_propagated_action_reaches_resource_controllers
    get("/api/demo/movies/ping.json")
    assert_response(:success)
    assert_equal("pong", response.parsed_body["message"])
  end

  def test_exclude_self_action_reaches_descendants_but_not_the_declaring_base
    get("/api/demo/movies/child_ping.json")
    assert_response(:success)

    # The `:exclude_self` action applies to descendants but not the base that declared it.
    refute_includes(Api::DemoController.actions.keys, :child_ping)
    assert_includes(Api::Demo::MoviesController.actions.keys, :child_ping)
  end

  def test_child_controller_can_remove_a_propagated_action
    # Movies still has the propagated `ping`...
    get("/api/demo/movies/ping.json")
    assert_response(:success)
    assert_equal("pong", response.parsed_body["message"])

    # ...but genres removed it locally, so it's absent from the store. (`/genres/ping` no longer
    # resolves to the ping action — it falls through to the member `show` route and 404s.)
    refute_includes(Api::Demo::GenresController.actions.keys, :ping)
    get("/api/demo/genres/ping.json")
    assert_response(:not_found)
  end

  # Only Rails>=8.1 due to changes in integration test behavior.
  if Rails::VERSION::MAJOR >= 8 && Rails::VERSION::MINOR >= 1
    def test_can_not_get_network_resourceful_routes
      assert_raises(ActionController::RoutingError) do
        get("/api/demo/network.json")
      end
      assert_raises(ActionController::RoutingError) do
        get("/api/demo/network")
      end
    end
  end
end
