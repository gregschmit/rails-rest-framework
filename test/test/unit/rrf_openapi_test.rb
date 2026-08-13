require "test_helper"

class RRFOpenapiTest < ActiveSupport::TestCase
  # The OpenAPI schema is shared between request and response bodies, so it must mark `read_only`
  # fields `readOnly` and `write_only` fields `writeOnly` — otherwise a write-only field (e.g. a
  # password) would read as a returnable response property.
  def test_schema_annotates_read_only_and_write_only_fields
    controller = Class.new(Api::TestController) do
      self.model = User
      self.fields = { config: { balance: { write_only: true } } }
    end
    props = controller.openapi_schema[:properties]

    assert_equal(true, props["balance"][:writeOnly])
    assert_nil(props["balance"][:readOnly])

    # The primary key is read-only by default and must stay marked readOnly (and not writeOnly).
    assert_equal(true, props["id"][:readOnly])
    assert_nil(props["id"][:writeOnly])
  end

  # A true ActiveRecord enum populates `options` (inverted to `{ value => label }`) and is marked
  # `enum: true`, so OpenAPI emits both a strict `enum` (the values) and the full `x-rrf-options`
  # map. A non-enum field that merely configures `options` gets `x-rrf-options` but no `enum`.
  def test_schema_options_and_enum
    controller = Class.new(Api::TestController) do
      self.model = User
      # `status` is a plain string column; give it explicit choices via `options`.
      self.fields = { config: { status: { options: User::STATUS_OPTS } } }
    end
    props = controller.openapi_schema[:properties].as_json

    # `state` is a real enum: strict `enum` (the stored values) plus the inverted options map.
    assert_equal([ 0, 1, 2, 3 ], props["state"]["enum"])
    assert_equal(
      { "0" => "default", "1" => "pending", "2" => "banned", "3" => "archived" },
      props["state"]["x-rrf-options"],
    )

    # `status` only has configured options, so no strict `enum`, just the choice map.
    assert_nil(props["status"]["enum"])
    assert_equal(User::STATUS_OPTS.as_json, props["status"]["x-rrf-options"])
  end

  # `x-rrf-validators` carries raw validator options, which for inclusion validators can hold a
  # static array, a symbol (method name), or a Proc/lambda (dynamic set). None of these break JSON
  # rendering: an array serializes as-is, a symbol as a string, and a Proc/lambda as `{}` (signaling
  # an inclusion constraint whose set isn't statically known). These assertions pin that contract so
  # a future change can't silently make the metadata non-serializable.
  def test_schema_serializes_inclusion_validators_with_arrays_symbols_and_procs
    controller = Class.new(Api::TestController) { self.model = User }
    props = controller.openapi_schema[:properties].as_json

    # `state` has three inclusion validators: a static array, a lambda, and a Proc.
    assert_equal(
      { "inclusion" => [
        { "in" => %w[default pending banned archived] },
        { "in" => {} },
        { "in" => {} },
      ] },
      props["state"]["x-rrf-validators"],
    )

    # `status` has two: a static array and a symbol naming a method.
    assert_equal(
      { "inclusion" => [
        { "in" => [ "", "online", "offline", "busy" ] },
        { "in" => "status_keys" },
      ] },
      props["status"]["x-rrf-validators"],
    )
  end
end
