require "test_helper"

# Write-only fields never appear in serialized output, so they must be excluded from every read-side
# query surface: `readable_fields` (the shared source) and each filter backend's fallback field list
# (find_by is covered by `find_by_controller_test`).
class RRFWriteOnlyQuerySurfaceTest < ActiveSupport::TestCase
  def controller
    @controller ||= Class.new(Api::TestController) do
      self.model = User
      # `login` is a readable column; `legal_name` is a real column marked write_only.
      self.fields = %w[id login legal_name]
      self.write_only_fields = %w[legal_name]
    end.new
  end

  def test_readable_fields_excludes_write_only
    assert_includes(controller.readable_fields, "login")
    assert_not_includes(controller.readable_fields, "legal_name")
  end

  def test_filter_backends_fall_back_to_readable_fields
    [
      RESTFramework::QueryFilter,
      RESTFramework::OrderingFilter,
      RESTFramework::SearchFilter,
    ].each do |backend|
      fields = backend.new(controller: controller)._get_fields
      assert_not_includes(fields, "legal_name", "#{backend} exposed a write_only field")
    end
  end
end
