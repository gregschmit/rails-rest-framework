require_relative '../test_helper'


# Common tests for all models.
module BaseModelTests
  def _get_model
    return self.class.name.match(/(.*)Test$/)[1].constantize
  end

  def test_record_exists_from_fixture
    model = self._get_model
    assert model.exists?
  end

  def test_can_destroy_record
    model = self._get_model
    model.first.destroy!
  end
end
