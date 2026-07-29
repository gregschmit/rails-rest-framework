require "test_helper"

# Tests for the declarative action store (`add_*`/`remove_*` helpers and the `actions` /
# `member_actions` readers).
class RRFActionsTest < Minitest::Test
  def controller(&block)
    Class.new(ActionController::Base) do
      include RESTFramework::Controller
      class_eval(&block) if block
    end
  end

  def capture_warnings
    original = Rails.logger
    io = StringIO.new
    Rails.logger = Logger.new(io)
    yield
    io.string
  ensure
    Rails.logger = original
  end

  # --- Builtins gating (Q4: only when applicable) ---

  def test_modelless_controller_exposes_only_root_and_options
    c = controller

    assert_equal([ :options, :root ], c.actions.keys.sort)
    assert_empty(c.member_actions.keys)
  end

  def test_plural_model_controller_exposes_crud_builtins
    c = controller { self.model = User }

    assert_equal([ :create, :index, :options ], c.actions.keys.sort)
    assert_equal([ :destroy, :show, :update ], c.member_actions.keys.sort)
    refute_includes(c.actions.keys, :root, "root is only for modelless controllers")
  end

  def test_bulk_enables_bulk_builtins
    c = controller { self.model = User; self.bulk = true }

    assert_includes(c.actions.keys, :update_all)
    assert_includes(c.actions.keys, :destroy_all)
  end

  def test_singular_model_controller_has_no_index
    c = controller { self.model = User; self.singular = true }

    refute_includes(c.actions.keys, :index)
    assert_includes(c.actions.keys, :create)
    assert_includes(c.member_actions.keys, :show)
  end

  # --- Adding ---

  def test_add_collection_action_builds_a_spec
    c = controller { add_collection_action(:help, :post, path: :assist, metadata: { a: 1 }) }
    spec = c.actions[:help]

    assert_equal([ :post ], spec.methods)
    assert_equal("assist", spec.path)
    assert_equal({ a: 1 }, spec.metadata)
    refute(spec.builtin)
  end

  def test_add_member_action_normalizes_multiple_methods
    c = controller { self.model = User; add_member_action(:archive, [ :put, :patch ]) }

    assert_equal([ :put, :patch ], c.member_actions[:archive].methods)
  end

  def test_bare_add_action_targets_collection_and_warns_only_on_model_controllers
    model_warnings = capture_warnings { controller { self.model = User; add_action(:foo, :get) } }
    assert_includes(model_warnings, "add_action")

    modelless_warnings = capture_warnings { controller { add_action(:foo, :get) } }
    refute_includes(modelless_warnings, "add_action")

    c = controller { add_action(:foo, :get) }
    assert_includes(c.actions.keys, :foo)
  end

  # --- Removing (replaces excluded_actions) ---

  def test_remove_disables_builtins
    c = controller do
      self.model = User
      remove_collection_action(:index)
      remove_member_action(:destroy)
    end

    refute_includes(c.actions.keys, :index)
    refute_includes(c.member_actions.keys, :destroy)
    assert_includes(c.actions.keys, :create, "unrelated builtins remain")
  end

  def test_remove_actions_splat
    c = controller { self.model = User; remove_member_actions(:update, :destroy) }

    refute_includes(c.member_actions.keys, :update)
    refute_includes(c.member_actions.keys, :destroy)
    assert_includes(c.member_actions.keys, :show)
  end

  def test_bare_remove_removes_both_scopes_on_model_controllers_without_warning
    c = nil
    warnings = capture_warnings do
      c = controller do
        self.model = User
        add_collection_action(:foo, :get)
        add_member_action(:foo, :get)
        remove_action(:foo)
      end
    end

    refute_includes(c.actions.keys, :foo)
    refute_includes(c.member_actions.keys, :foo)
    # Bare `remove_action` must not warn on model controllers.
    refute_includes(warnings, "ambiguous")
  end

  def test_bare_remove_on_a_modelless_controller_removes_only_the_collection
    c = controller do
      add_collection_action(:foo, :get)
      add_member_action(:foo, :get)
      remove_action(:foo)
    end

    refute_includes(c.actions.keys, :foo)
    assert_includes(c.member_actions.keys, :foo)
  end

  # --- Propagation (§5) ---

  def test_local_add_does_not_propagate
    base = controller { add_collection_action(:help, :get) }
    child = Class.new(base)

    assert_includes(base.actions.keys, :help)
    refute_includes(child.actions.keys, :help)
  end

  def test_propagate_true_reaches_self_and_descendants
    base = controller { add_collection_action(:help, :get, propagate: true) }
    child = Class.new(base)
    grandchild = Class.new(child)

    assert_includes(base.actions.keys, :help)
    assert_includes(child.actions.keys, :help)
    assert_includes(grandchild.actions.keys, :help)
  end

  def test_propagate_exclude_self_reaches_descendants_only
    base = controller { add_collection_action(:help, :get, propagate: :exclude_self) }
    child = Class.new(base)

    refute_includes(base.actions.keys, :help)
    assert_includes(child.actions.keys, :help)
  end

  def test_invalid_propagate_value_is_treated_as_true_with_a_warning
    child = nil
    warnings = capture_warnings do
      base = controller { add_collection_action(:help, :get, propagate: "yes") }
      child = Class.new(base)
    end

    assert_includes(warnings, "propagate")
    assert_includes(child.actions.keys, :help)
  end

  def test_local_remove_below_a_propagated_add
    base = controller { add_collection_action(:help, :get, propagate: true) }
    child = Class.new(base) { remove_collection_action(:help) }
    grandchild = Class.new(child)

    assert_includes(base.actions.keys, :help)
    refute_includes(child.actions.keys, :help, "removed locally on the child")
    assert_includes(grandchild.actions.keys, :help, "ancestor's propagated add still reaches here")
  end

  def test_subclass_can_readd_a_propagated_removed_action
    base = controller do
      add_collection_action(:help, :get, propagate: true)
      remove_collection_action(:help, propagate: true)
    end
    child = Class.new(base) { add_collection_action(:help, :post) }

    refute_includes(base.actions.keys, :help)
    assert_includes(child.actions.keys, :help)
    assert_equal([ :post ], child.actions[:help].methods)
  end

  def test_adding_a_builtin_named_action_is_a_plain_extra_action
    # Adding an action with a builtin's name overrides that builtin's spec with a plain extra action
    # at `/name` — it is NOT reinterpreted as the builtin at the resource root. (Holds on model and
    # modelless controllers alike; pass `path: ""` to route at the root.)
    on_model = controller { self.model = User; add_collection_action(:create, :post) }
    assert_equal("create", on_model.actions[:create].path)
    refute(on_model.actions[:create].builtin)

    modelless = controller { add_action(:index, :get) }
    assert_equal("index", modelless.actions[:index].path)
    refute(modelless.actions[:index].builtin)
  end
end
