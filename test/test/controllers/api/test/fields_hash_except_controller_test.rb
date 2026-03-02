require "test_helper"

class Api::Test::FieldsHashExceptControllerTest < ActionController::TestCase
  def test_list
    get(:index, as: :json)
    assert_response(:success)
    assert_not(@response.parsed_body[0].key?("balance"))
  end
end
