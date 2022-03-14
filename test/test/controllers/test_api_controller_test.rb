require "test_helper"

class DemoApiControllerTest < ActionController::TestCase
  def test_can_hit_root
    get(:root)
    assert_response(:success)

    [:json, :xml].each do |fmt|
      get(:root, format: fmt)
      assert_response(:success)
    end
  end
end
