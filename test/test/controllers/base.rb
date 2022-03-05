require_relative '../test_helper'

# Common tests for Api controllers.
module BaseApiControllerTests
  def test_can_hit_root
    get :root
    assert_response :success

    [:json, :xml].each do |fmt|
      get :root, format: fmt
      assert_response :success
    end
  end
end
