require_relative '../test_helper'


class RESTFrameworkTest < Minitest::Test
  def test_version_number
    refute_nil RESTFramework::VERSION
  end

  def test_get_version
    assert RESTFramework::Version.get_version
    assert RESTFramework::Version.get_version(skip_git: true)
  end
end
