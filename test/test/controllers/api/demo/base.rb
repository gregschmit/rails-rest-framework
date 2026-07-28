require_relative "../../base_crud"

module Api::Demo::Base
  include BaseCRUD

  def self.included(base)
    base.class_attribute(:create_params)
    base.class_attribute(:update_params)
  end

  def test_index_with_filtering
    filter_key = self.class.create_params.keys[0]
    filter_value = self._get_model.first.send(filter_key)
    get(:index, as: :json, params: { "#{filter_key}": filter_value })
    assert_response(:success)
    assert(@response.parsed_body["results"].all? { |r| r[filter_key.to_s] == filter_value })
  end

  # User-supplied nested-hash query params (e.g. `?login[evil]=x`) must not 500
  # the request via `TypeError (can't quote ActiveSupport::HashWithIndifferentAccess)`
  # when they flow into ActiveRecord bind values.

  def test_index_with_hash_value_for_filter_field_is_ignored
    filter_key = self.class.create_params.keys[0]
    get(:index, as: :json, params: { "#{filter_key}": { "evil" => "x" } })
    assert_response(:success)
  end

  def test_index_with_hash_value_for_predicate_field_is_ignored
    filter_key = self.class.create_params.keys[0]
    get(:index, as: :json, params: { "#{filter_key}_cont": { "evil" => "x" } })
    assert_response(:success)
  end

  def test_index_with_hash_value_for_search_param_is_ignored
    get(:index, as: :json, params: { search: { "evil" => "x" } })
    assert_response(:success)
  end

  def test_index_with_hash_value_for_ordering_param_is_ignored
    get(:index, as: :json, params: { ordering: { "evil" => "x" } })
    assert_response(:success)
  end
end
