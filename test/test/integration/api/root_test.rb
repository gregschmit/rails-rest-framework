require "test_helper"

# The API root and each namespace root are served by the base controller's `index` (rendering
# `index_content`) — there are no dedicated root controllers.
class Api::RootTest < ActionDispatch::IntegrationTest
  def test_api_root_renders_the_welcome
    get("/api.json")

    assert_response(:success)
    assert_includes(response.parsed_body["message"], "three APIs")
    assert(response.parsed_body.key?("demo_api"))
  end

  def test_each_namespace_root_renders_its_own_content_not_the_inherited_welcome
    {
      "/api/plain.json" => Api::PlainController::DESCRIPTION,
      "/api/demo.json" => Api::DemoController::DESCRIPTION,
      "/api/test.json" => Api::TestController::DESCRIPTION,
    }.each do |path, description|
      get(path)

      assert_response(:success)
      assert_equal(description, response.parsed_body["message"])
    end
  end
end
