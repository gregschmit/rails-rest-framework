require "test_helper"

# The goal of this test is to ensure unknown formats are rescued, when configured.
class RescuingUnknownFormatsTest < ActionDispatch::IntegrationTest
  # Test that an invalid format raises an uncaught exception.
  # Only Rails >=8 due to changes in integration test behavior.
  if Rails::VERSION::MAJOR >= 8
    def test_raise_unknown_format
      get("/api/test/no_rescue_unknown_format.jsom")
      assert_response(:not_acceptable)
    end
  end

  # Test that we rescue an unknown format and also that it defaults to :json.
  def test_rescue_unknown_format
    get("/api/test/users.json")
    assert_response(:success)
    resp1 = @response.body

    get("/api/test/users.jsom")
    assert_response(:success)
    resp2 = @response.body

    assert_equal(resp1, resp2)
  end
end
