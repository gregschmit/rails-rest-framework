require "test_helper"

# A read_only association must not expand into permitted assignment keys. Strong parameters translate
# an association into `<name>_id`/`<name>_attributes`, so filtering read-only fields has to happen
# before that expansion (in `writable_fields`) rather than after, where those keys no longer match a
# field name.
class RRFReadOnlyAssociationParamsTest < ActiveSupport::TestCase
  def build_controller(field_config)
    Class.new(Api::TestController) do
      self.model = User
      self.fields = [ :id, :login, :manager ]
      self.field_config = field_config
    end.new
  end

  def permitted_keys(controller)
    controller.get_allowed_parameters.flat_map { |p|
      p.is_a?(Hash) ? p.keys.map(&:to_s) : p.to_s
    }
  end

  def test_writable_association_permits_id_and_attributes
    controller = build_controller({})
    keys = permitted_keys(controller)
    assert_includes(keys, "manager_id")
    assert_includes(keys, "manager_attributes")

    # The variations survive an actual `permit` of post-transformation data, while the read-only
    # primary key and a non-permitted nested attribute are dropped.
    permitted = ActionController::Parameters.new(
      login: "x", id: 99, manager_id: 5, manager_attributes: { login: "m", is_admin: true },
    ).permit(*controller.get_allowed_parameters)
    assert_equal(
      { "login" => "x", "manager_id" => 5, "manager_attributes" => { "login" => "m" } },
      permitted.to_h,
    )
  end

  def test_read_only_association_permits_no_assignment_keys
    keys = permitted_keys(build_controller({ manager: { read_only: true } }))
    assert_not_includes(keys, "manager_id")
    assert_not_includes(keys, "manager_attributes")
    # The bare association form is never permitted either.
    assert_not_includes(keys, "manager")
  end
end
