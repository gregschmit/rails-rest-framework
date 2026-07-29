require "test_helper"

class Api::TestControllerTest < ActionController::TestCase
  def test_can_hit_root
    get(:index)
    assert_response(:success)

    [ :json, :xml ].each do |fmt|
      get(:index, format: fmt)
      assert_response(:success)
    end
  end
end
