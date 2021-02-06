require_relative '../test_helper'

class RESTFrameworkTest < Minitest::Test
  def test_version_number
    refute_nil RESTFramework::VERSION
  end
end
