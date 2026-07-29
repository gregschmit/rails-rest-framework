require "test_helper"

class Api::PlainControllerTest < ActionController::TestCase
  def test_index_renders_the_root
    get(:index)
    assert_response(:success)

    get(:index, format: :json)
    assert_response(:success)

    get(:index, format: :xml)
    assert_response(:success)
  end
end
