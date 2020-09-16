require_relative '../../test_helper'
require_relative 'app'

class App1Test < ActiveSupport::TestCase  # transactional tests
  def test_can_create_thing
    refute Thing.exists?
    t = Thing.create!(name: 'test')
    assert_equal(t.name, 'test')
    assert Thing.exists?
  end
end
