require_relative '../test_helper'

class ThingTest < ActiveSupport::TestCase
  def test_can_create_thing
    Thing.create!(name: 'test_create')
    assert Thing.where(name: 'test_create').exists?
  end

  def test_can_update_thing
    t = Thing.create!(name: 'test_update')
    t.update!(name: 'new_testupdate')
    assert Thing.where(name: 'new_testupdate').exists?
  end

  def test_thing_exists_from_fixture
    assert Thing.where(name: 'Thing 1').exists?
  end
end
