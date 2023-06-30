require "test_helper"

class Api::Plain::RootControllerTest < ActionController::TestCase
  def test_root
    get(:root)
    assert_response(:success)

    get(:root, format: :json)
    assert_response(:success)

    get(:root, format: :xml)
    assert_response(:success)
  end
end
