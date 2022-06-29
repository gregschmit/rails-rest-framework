require_relative "base"

class TestApi::ThingsWithoutRescueUnknownFormatControllerTest < ActionController::TestCase
  include BaseTestApiControllerTests

  # def test_unknown_format_not_rescued
  #   assert_raises(ActionController::UnknownFormat) do
  #     get("index.jsom")
  #   end
  # end
end
