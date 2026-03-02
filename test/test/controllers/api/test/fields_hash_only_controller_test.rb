require "test_helper"

class Api::Test::FieldsHashOnlyControllerTest < ActionController::TestCase
  def test_list
    get(:index, as: :json)
    assert_response(:success)
    assert_equal(
      [
        "age",
        "balance",
        "id",
        "login",
      ],
      @response.parsed_body[0].keys.sort,
    )
  end
end
