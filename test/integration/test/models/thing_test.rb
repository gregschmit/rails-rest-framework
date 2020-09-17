require_relative '../test_helper'

class ThingTest < ActiveSupport::TestCase
  def test_can_create_thing1
    refute Thing.exists?
    t = Thing.create!(name: 'test1')
    assert_equal(t.name, 'test1')
    assert Thing.exists?
  end

  def test_can_create_thing2
    refute Thing.exists?
    t = Thing.create!(name: 'test2')
    assert_equal(t.name, 'test2')
    assert Thing.exists?
  end

  def test_can_create_thing3
    refute Thing.exists?
    t = Thing.create!(name: 'test2')
    assert_equal(t.name, 'test2')
    assert Thing.exists?
  end

  def test_can_create_thing4
    refute Thing.exists?
    t = Thing.create!(name: 'test2')
    assert_equal(t.name, 'test2')
    assert Thing.exists?
  end

  def test_can_create_thing5
    refute Thing.exists?
    t = Thing.create!(name: 'test2')
    assert_equal(t.name, 'test2')
    assert Thing.exists?
  end
end
