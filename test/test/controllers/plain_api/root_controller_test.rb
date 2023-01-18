require "test_helper"

class PlainApi::RootControllerTest < ActionController::TestCase
  def test_root
    get(:root)
    assert_response(:success)

    get(:root, format: :json)
    assert_response(:success)

    get(:root, format: :xml)
    assert_response(:success)
  end
end
