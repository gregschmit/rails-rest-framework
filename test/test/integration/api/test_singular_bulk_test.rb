require "test_helper"

# A singular controller never bulks, even with `bulk` set: `get_recordset` is not scoped to its one
# record, so a bulk action there would reach every row of the model.
class Api::TestSingularBulkTest < ActionDispatch::IntegrationTest
  def test_writes_route_to_the_member_actions
    { put: "update", patch: "update", delete: "destroy" }.each do |verb, action|
      assert_recognizes(
        { controller: "api/test/user", action: action }, { path: "/api/test/user", method: verb }
      )
    end
  end

  def test_array_post_does_not_bulk_create
    post("/api/test/user", params: [ { login: "bulk_a" }, { login: "bulk_b" } ], as: :json)

    refute_equal("Bulk create successful.", @response.parsed_body["message"])
    refute(User.exists?(login: %w[bulk_a bulk_b]))
  end

  def test_openapi_does_not_advertise_bulk_create
    options("/api/test/user", as: :json)

    assert_response(:success)
    assert_equal(false, @response.parsed_body["x-rrf-bulk-create"])
  end
end
