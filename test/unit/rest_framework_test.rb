require_relative 'unit_test_helper'

class RESTFrameworkTest < Minitest::Test
  parallelize_me!  # unit tests can be parallelized

  def test_version_number
    refute_nil RESTFramework::VERSION
  end

  def test_it_does_something_useful
    assert true
  end
end
