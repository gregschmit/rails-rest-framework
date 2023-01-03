require_relative "base"

class TestApi::ThingsWithAddedSelectControllerTest < ActionController::TestCase
  include BaseTestApiControllerTests

  def test_only_works
    get(:index, as: :json, params: {only: "id,selected_value"})
    assert_response(:success)
    assert_equal(["id", "selected_value"].sort, @response.parsed_body[0].keys.sort)
  end

  def test_except_works
    get(:index, as: :json, params: {except: "id"})
    assert_response(:success)
    assert_equal(
      [
        "created_at", "is_discounted", "name", "owner_id", "selected_value", "shape", "updated_at"
      ].sort,
      @response.parsed_body[0].keys.sort,
    )
  end
end
