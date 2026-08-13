require "test_helper"

# The `fields` spec unifies set membership (`only`/`include`/`exclude`/`except`) with per-field
# `config` in one structure, at the top level and inside an association's `fields`. A field named in
# `config` is implicitly part of the set, so it never has to be listed twice.
class RRFFieldsSpecTest < ActiveSupport::TestCase
  def fields_for(fields)
    Class.new(Api::TestController) do
      self.model = User
      self.fields = fields
    end.get_fields
  end

  def test_bare_array_is_sugar_for_only
    assert_equal(%w[id login], fields_for([ :id, :login ]))
  end

  def test_config_field_is_implicitly_included
    assert_equal(%w[id login], fields_for({ only: [ :id ], config: { login: { label: "Login" } } }))
  end

  def test_except_is_an_alias_for_exclude
    assert_equal(%w[id login], fields_for({ only: %w[id login balance], except: %w[balance] }))
    assert_equal(%w[id login], fields_for({ only: %w[id login balance], exclude: %w[balance] }))
  end

  def test_exclude_is_applied_last_and_wins_over_config_inclusion
    fields = fields_for(
      { only: %w[id login], exclude: %w[login], config: { login: { label: "L" } } },
    )
    assert_equal(%w[id], fields)
  end

  def test_association_config_field_is_implicitly_included
    klass = Class.new(Api::TestController) do
      self.model = User
      self.fields = {
        only: [ :id, :manager ],
        config: { manager: { fields: { config: { balance: { label: "B" } } } } },
      }
    end

    # `manager`'s default fields (id + label) are extended by the `balance` config entry.
    assert_includes(klass.field_configuration["manager"][:fields], "balance")
  end
end
