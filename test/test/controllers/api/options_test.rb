require "test_helper"

class Api::OptionsTest < ActionDispatch::IntegrationTest
  def test_api_options
    options "/api"
    assert_response(:success)
  end

  def test_plain_api_options
    options "/api/plain"
    assert_response(:success)

    options "/api/plain", as: :json
    assert_response(:success)

    options "/api/plain", as: :xml
    assert_response(:success)
  end

  def test_demo_api_options
    options "/api/demo"
    assert_response(:success)

    # Verify openapi_include_children merges child controller paths (e.g., /emails).
    options "/api/demo", as: :json
    assert_response(:success)
    body = @response.parsed_body
    assert(body["paths"].keys.any? { |p| p.include?("emails") }, "Expected child path /emails")
  end

  def test_test_api_options
    options "/api/test"
    assert_response(:success)

    options "/api/test/users"
    assert_response(:success)
  end
end
