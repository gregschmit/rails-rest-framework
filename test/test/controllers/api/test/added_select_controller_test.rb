require "test_helper"

class Api::Test::AddedSelectControllerTest < ActionController::TestCase
  def test_only_works
    get(:index, as: :json, params: { only: "id,selected_value" })
    assert_response(:success)
    assert_equal([ "id", "selected_value" ].sort, @response.parsed_body[0].keys.sort)
  end

  def test_except_works
    get(:index, as: :json, params: { except: "id" })
    assert_response(:success)
    assert(@response.parsed_body[0]["selected_value"])
    refute(@response.parsed_body[0]["id"])
  end
end
