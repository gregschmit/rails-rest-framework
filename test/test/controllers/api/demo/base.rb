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

  # A scalar predicate given an array value (e.g. `?name_cont[]=a&name_cont[]=b`, which Rack parses
  # into an array) must be ignored, not 500: `cont` would raise in `sanitize_sql_like` and the range
  # predicates while casting the endpoint. Only `in`/`not` accept arrays.
  def test_index_with_array_value_for_scalar_predicate_is_ignored
    filter_key = self.class.create_params.keys[0]

    get(:index, as: :json, params: { "#{filter_key}_cont": [ "a", "b" ] })
    assert_response(:success)

    get(:index, as: :json, params: { "#{filter_key}_lt": [ "a", "b" ] })
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
