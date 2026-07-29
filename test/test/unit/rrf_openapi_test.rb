require "test_helper"

class RRFOpenapiTest < ActiveSupport::TestCase
  # The OpenAPI schema is shared between request and response bodies, so it must mark `read_only`
  # fields `readOnly` and `write_only` fields `writeOnly` — otherwise a write-only field (e.g. a
  # password) would read as a returnable response property.
  def test_schema_annotates_read_only_and_write_only_fields
    controller = Class.new(Api::TestController) do
      self.model = User
      self.field_config = { balance: { write_only: true } }
    end
    props = controller.openapi_schema[:properties]

    assert_equal(true, props["balance"][:writeOnly])
    assert_nil(props["balance"][:readOnly])

    # The primary key is read-only by default and must stay marked readOnly (and not writeOnly).
    assert_equal(true, props["id"][:readOnly])
    assert_nil(props["id"][:writeOnly])
  end
end
