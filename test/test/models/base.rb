require_relative '../test_helper'


# Common tests for all models.
module BaseModelTests
  def _get_model
    return @_get_model ||= self.class.name.match(/(.*)Test$/)[1].constantize
  end

  def test_fixtures_are_valid
    self._get_model.all.each { |r| assert r.valid? }
  end

  def test_record_exists_from_fixture
    assert self._get_model.exists?
  end

  def test_can_destroy_record
    self._get_model.first.destroy!
  end
end
