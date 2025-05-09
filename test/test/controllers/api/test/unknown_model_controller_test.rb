require "test_helper"

class Api::Test::UnknownModelControllerTest < ActionController::TestCase
  def test_unknown_model_raised
    assert_raises(RESTFramework::UnknownModelError) do
      get(:index)
    end
  end
end
