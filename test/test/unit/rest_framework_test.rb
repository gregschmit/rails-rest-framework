require_relative '../test_helper'

class UnserializableThing
end

class UnserializableSerializer < RESTFramework::NativeSerializer
  self.config = {only: [:id, :name]}
end

class RESTFrameworkTest < Minitest::Test
  def test_version_number_not_nil
    refute_nil RESTFramework::VERSION
  end

  def test_get_version_git
    assert RESTFramework::Version.get_version != 'unknown'
  end

  def test_get_version_stamp
    RESTFramework::Version.unstamp_version
    assert RESTFramework::Version.get_version(skip_git: true) == 'unknown'
    RESTFramework::Version.stamp_version
    assert RESTFramework::Version.get_version(skip_git: true) != 'unknown'
  end

  def test_unserializable_serializer
    unserializable_object = UnserializableThing.new
    exception = assert_raises NoMethodError do
      UnserializableSerializer.new(object: unserializable_object).serialize
    end
    assert exception.message
  end

  def test_base_filter_get_filtered_data_not_implemented
    assert_raises NotImplementedError do
      RESTFramework::BaseFilter.new(controller: nil).get_filtered_data([])
    end
  end

  def test_base_serializer_serialize_not_implemented
    assert_raises NotImplementedError do
      RESTFramework::BaseSerializer.new.serialize
    end
  end

  def test_base_paginator_get_page_not_implemented
    assert_raises NotImplementedError do
      RESTFramework::BasePaginator.new(data: [], controller: nil).get_page
    end
  end

  def test_base_paginator_get_paginated_response_not_implemented
    assert_raises NotImplementedError do
      RESTFramework::BasePaginator.new(data: [], controller: nil).get_paginated_response(nil)
    end
  end
end
