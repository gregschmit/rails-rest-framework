require "test_helper"

# `add_action(..., propagate: ->(controller) { ... })` gates an action with a predicate: it applies
# to the controller and its descendants wherever the predicate holds (e.g. only where a model is
# set), evaluated during action composition.
class RRFConditionalActionTest < ActiveSupport::TestCase
  def test_propagate_predicate_gates_by_controller
    base = Class.new(Api::TestController) do
      add_action(:stats, :get, propagate: ->(c) { c.model })
    end
    with_model = Class.new(base) { self.model = User }
    without_model = Class.new(base)

    # Applies to the descendant with a model; not the modelless base or modelless descendant.
    assert_includes(with_model.actions.keys, :stats)
    assert_not_includes(base.actions.keys, :stats)
    assert_not_includes(without_model.actions.keys, :stats)
  end

  def test_propagate_true_reaches_all_descendants
    base = Class.new(Api::TestController) { add_action(:stats, :get, propagate: true) }
    assert_includes(Class.new(base).actions.keys, :stats)
    assert_includes(base.actions.keys, :stats)
  end

  def test_propagate_predicate_also_gates_the_declaring_controller
    plain = Class.new(Api::TestController) do
      self.model = User
      add_action(:only_bulk, :get, type: :collection, propagate: ->(c) { c.bulk })
    end
    assert_not_includes(plain.actions.keys, :only_bulk)

    bulk = Class.new(Api::TestController) do
      self.model = User
      self.bulk = true
      add_action(:only_bulk, :get, type: :collection, propagate: ->(c) { c.bulk })
    end
    assert_includes(bulk.actions.keys, :only_bulk)
  end
end
