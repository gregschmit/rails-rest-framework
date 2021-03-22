require_relative 'base'


class UserTest < ActiveSupport::TestCase
  include BaseModelTests

  def test_can_create_user
    Thing.create!(name: 'test_create')
    assert Thing.where(name: 'test_create').exists?
  end

  def test_can_update_user
    t = Thing.create!(name: 'test_update')
    t.update!(name: 'new_testupdate')
    assert Thing.where(name: 'new_testupdate').exists?
  end
end
