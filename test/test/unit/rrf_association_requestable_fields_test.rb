require "test_helper"

# The per-association requestable-fields allowlist is compiled once into `field_configuration` (like
# `read_only`), rather than resolved per request.
class RRFAssociationRequestableFieldsTest < ActiveSupport::TestCase
  def test_sibling_derived_allowlist_is_compiled_into_field_configuration
    cfg = Api::Test::AssocExp::UsersController.field_configuration["manager"]

    # The sibling is this controller itself (self-referential), so resolving the allowlist during
    # `field_configuration` must not recurse. It's what the sibling serializes:
    assert_includes(cfg[:requestable_fields], "age")
    assert_includes(cfg[:requestable_fields], "balance") # hidden, but serializable
    refute_includes(cfg[:requestable_fields], "is_admin") # write_only
    refute_includes(cfg[:requestable_fields], "manager") # nested association
  end

  def test_explicit_allowlist_is_left_as_is
    cfg = Api::Test::AssocExp::UsersExplicitController.field_configuration["manager"]

    assert_equal(%w[age], cfg[:requestable_fields])
  end

  def test_not_compiled_when_feature_disabled
    cfg = Api::Test::AssocExp::UsersDisabledController.field_configuration["manager"]

    assert_nil(cfg[:requestable_fields])
  end
end
