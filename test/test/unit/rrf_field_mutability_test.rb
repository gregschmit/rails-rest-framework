require "test_helper"

# `field_configuration` read_only/write_only precedence: an explicit `read_only`/`write_only` (in a
# field's `config`, or a write_only via the `write_only_fields` config) wins over the framework's
# defaults. Notably the method-field read-only default must not force `read_only: true` onto a
# write_only field (which would leave it neither serialized nor writable).
class RRFFieldMutabilityTest < ActiveSupport::TestCase
  def cfg_for(field, fields:, config: {}, write_only_fields: nil)
    klass = Class.new(Api::TestController) do
      self.model = User
      self.fields = { only: fields, config: config }
    end
    klass.write_only_fields = write_only_fields if write_only_fields
    klass.field_configuration[field.to_s]
  end

  def test_method_field_defaults_to_read_only
    cfg = cfg_for(:calculated_property, fields: %w[id calculated_property])
    assert_equal("method", cfg[:kind])
    assert(cfg[:read_only])
  end

  def test_write_only_method_field_is_not_forced_read_only
    cfg = cfg_for(
      :calculated_property,
      fields: %w[id calculated_property],
      config: { calculated_property: { write_only: true } },
    )
    assert(cfg[:write_only])
    assert_nil(cfg[:read_only], "write_only should suppress the method read-only default")
  end

  def test_explicit_read_only_false_wins_over_the_method_default
    cfg = cfg_for(
      :calculated_property,
      fields: %w[id calculated_property],
      config: { calculated_property: { read_only: false } },
    )
    assert_equal(false, cfg[:read_only])
  end

  def test_write_only_fields_config_also_suppresses_the_method_default
    cfg = cfg_for(
      :calculated_property,
      fields: %w[id calculated_property],
      write_only_fields: %w[calculated_property],
    )
    assert(cfg[:write_only])
    assert_nil(cfg[:read_only])
  end

  def test_field_config_read_only_wins_over_the_read_only_fields_config
    # `created_at` is read-only by default (DEFAULT_READ_ONLY_FIELDS); explicit field_config wins.
    cfg = cfg_for(
      :created_at,
      fields: %w[id created_at],
      config: { created_at: { read_only: false } },
    )
    assert_equal(false, cfg[:read_only])
  end
end
