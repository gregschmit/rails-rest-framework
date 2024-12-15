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
    get(:index, as: :json, params: {"#{filter_key}": filter_value})
    assert_response(:success)
    assert(@response.parsed_body["results"].all? { |r| r[filter_key.to_s] == filter_value })
  end
end
