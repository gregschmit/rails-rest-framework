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
