require "test_helper"

# Tests for `rrf_class_attribute` / `propagate`, which power controller configuration inheritance.
# The rule is uniform: an assignment is LOCAL unless wrapped in a `propagate` block.
#
#   self.x = value                # local to this controller
#   propagate { self.x = value }  # propagates to this controller and all descendants
class RRFClassAttributeTest < Minitest::Test
  def build_tree
    base = Class.new do
      extend RESTFramework::Controller::ClassMethods

      rrf_class_attribute(:thing, default: :default_value)
    end
    child = Class.new(base)
    grandchild = Class.new(child)

    [ base, child, grandchild ]
  end

  def test_default_is_returned_when_unset
    base, child, grandchild = build_tree

    assert_equal(:default_value, base.thing)
    assert_equal(:default_value, child.thing)
    assert_equal(:default_value, grandchild.thing)
  end

  def test_plain_assignment_is_local_by_default
    base, child, grandchild = build_tree

    base.thing = :local

    assert_equal(:local, base.thing)
    assert_equal(:default_value, child.thing, "a plain assignment must not propagate")
    assert_equal(:default_value, grandchild.thing)
  end

  def test_propagate_block_propagates_to_descendants
    base, child, grandchild = build_tree

    base.propagate { base.thing = :shared }

    assert_equal(:shared, base.thing)
    assert_equal(:shared, child.thing)
    assert_equal(:shared, grandchild.thing)
  end

  def test_local_override_below_a_propagated_value
    base, child, grandchild = build_tree

    base.propagate { base.thing = :shared }
    child.thing = :child_local

    assert_equal(:shared, base.thing)
    assert_equal(:child_local, child.thing)
    # The grandchild skips the child's local value and falls back to the propagated one.
    assert_equal(:shared, grandchild.thing)
  end

  def test_propagate_reaches_descendants_below_an_earlier_local_override
    base, child, grandchild = build_tree

    # The child overrides locally BEFORE the base later shares a value via `propagate`.
    child.thing = :child_local
    base.propagate { base.thing = :shared }

    assert_equal(:shared, base.thing)
    assert_equal(:child_local, child.thing)
    # The grandchild hasn't overridden, so it must see the base's later-propagated value — not the
    # value that was in effect when the child's local getter was defined.
    assert_equal(:shared, grandchild.thing)
  end

  def test_local_assignment_on_the_declaring_class_falls_back_to_default_for_descendants
    base, child, _grandchild = build_tree

    # A local assignment on the class that DECLARED the attribute must not leak to descendants; they
    # fall back to the default (there is no propagated ancestor value above the declaring class).
    base.thing = :base_local

    assert_equal(:base_local, base.thing)
    assert_equal(:default_value, child.thing)
  end

  def test_child_local_does_not_affect_parent_or_siblings
    base, child, _grandchild = build_tree
    sibling = Class.new(base)

    child.thing = :child_local

    assert_equal(:default_value, base.thing)
    assert_equal(:child_local, child.thing)
    assert_equal(:default_value, sibling.thing)
  end

  def test_propagate_from_a_mid_level_controller
    base, child, grandchild = build_tree

    child.propagate { child.thing = :from_child }

    assert_equal(:default_value, base.thing, "an ancestor must be unaffected")
    assert_equal(:from_child, child.thing)
    assert_equal(:from_child, grandchild.thing)
  end

  def test_propagate_restores_local_behavior_after_block
    base, child, _grandchild = build_tree

    base.propagate { base.thing = :shared }
    # After the block the propagating flag is cleared, so this assignment is local again.
    base.thing = :local_again

    assert_equal(:local_again, base.thing)
    refute_equal(:local_again, child.thing, "the post-block assignment must not propagate")
  end

  def test_propagate_restores_flag_on_exception
    base, _child, _grandchild = build_tree

    assert_raises(RuntimeError) do
      base.propagate { raise "boom" }
    end

    refute(
      Thread.current[RESTFramework::Controller::ClassMethods::RRF_PROPAGATING_KEY],
      "the propagating flag must be cleared even when the block raises",
    )
  end

  def test_predicate_reflects_truthiness
    base = Class.new do
      extend RESTFramework::Controller::ClassMethods

      rrf_class_attribute(:flag, default: false)
    end

    refute(base.flag?)
    base.flag = true
    assert(base.flag?)
    base.flag = nil
    refute(base.flag?)
  end

  def test_multiple_names_are_independent
    base = Class.new do
      extend RESTFramework::Controller::ClassMethods

      rrf_class_attribute(:a, :b, default: 0)
    end

    base.a = 1

    assert_equal(1, base.a)
    assert_equal(0, base.b)
  end

  # `model` is no longer special-cased: it's local by default like every other attribute, and the
  # setter no longer warns.

  def build_controller_tree
    base = Class.new(ActionController::Base) do
      include RESTFramework::Controller
    end
    child = Class.new(base)

    [ base, child ]
  end

  def capture_rrf_deprecations
    collected = []
    original = RESTFramework.deprecator.behavior
    RESTFramework.deprecator.behavior = ->(message, *) { collected << message }
    yield
    collected
  ensure
    RESTFramework.deprecator.behavior = original
  end

  def test_model_is_local_by_default_and_does_not_warn
    base, child = build_controller_tree

    warnings = capture_rrf_deprecations { base.model = :fake_model }

    assert_equal(:fake_model, base.model)
    assert_nil(child.model, "model must not propagate")
    assert_empty(warnings, "`self.model =` should no longer warn")
  end

  def test_model_can_propagate_when_wrapped
    base, child = build_controller_tree

    base.propagate { base.model = :shared_model }

    assert_equal(:shared_model, base.model)
    assert_equal(:shared_model, child.model)
  end

  def test_extra_collection_actions_is_a_live_alias_for_extra_actions
    base, _child = build_controller_tree

    base.extra_actions = { foo: :get }
    assert_equal(
      { foo: :get }, base.extra_collection_actions, "reading the alias must reflect the value"
    )

    base.extra_collection_actions = { bar: :get }
    assert_equal({ bar: :get }, base.extra_actions, "writing the alias must set `extra_actions`")
  end
end
