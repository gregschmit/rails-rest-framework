require "test_helper"

module BaseCRUD
  def _get_model
    return @_get_model ||= self.class.name.match(
      /([a-zA-Z]+)ControllerTest$/,
    )[1].singularize.constantize
  end

  def test_index
    get(:index)
    assert_response(:success)

    [:json, :xml].each do |fmt|
      get(:index, as: fmt)
      assert_response(:success)
    end
  end

  if Rails::VERSION::MAJOR >= 7
    def test_options
      process(:options, method: "OPTIONS")
      assert_response(:success)
    end
  end

  def test_show
    id = self._get_model.first.id
    get(:show, params: {id: id})
    assert_response(:success)

    [:json, :xml].each do |fmt|
      get(:show, as: fmt, params: {id: id})
      assert_response(:success)
    end
  end

  def test_show_not_found
    id = self._get_model.all.pluck(:id).max + 1
    get(:show, params: {id: id})
    assert_response(404)

    [:json, :xml].each do |fmt|
      get(:show, as: fmt, params: {id: id})
      assert_response(404)
    end
  end

  def test_create
    post(:create, as: :json, params: self.class.create_params)
    assert_response(:success)
    assert(self._get_model.find_by(id: @response.parsed_body["id"]))
  end

  def test_cannot_create_with_specific_id
    try_id = self._get_model.first.id
    post(:create, as: :json, params: {id: try_id, **self.class.create_params})
    assert_response(:success)
    assert(@response.parsed_body["id"] != try_id)
    assert(self._get_model.find_by(id: @response.parsed_body["id"]))
  end

  def test_cannot_create_with_specific_created_at
    try_created_at = Time.new(2000, 1, 1)
    post(:create, as: :json, params: {created_at: try_created_at, **self.class.create_params})

    assert_response(:success)

    created_at_year = Time.parse(@response.parsed_body["created_at"]).year
    assert_equal(Time.now.year, created_at_year)
    refute_equal(try_created_at.year, created_at_year)

    assert(self._get_model.find_by(id: @response.parsed_body["id"]))
  end

  def test_update
    record = self._get_model.first

    # Check old properties aren't the same as the new ones we're assigning in update.
    assert(self.class.update_params.map { |k, v| record.send(k) != v }.all?)

    patch(:update, as: :json, params: {id: record.id}, body: self.class.update_params.to_json)
    assert_response(:success)

    # Ensure properties are updated.
    record.reload
    assert(self.class.update_params.map { |k, v| record.send(k) == v }.all?)
  end

  def test_destroy
    id = self._get_model.first.id
    delete(:destroy, params: {id: id})
    assert_response(:success)
    assert_nil(self._get_model.find_by(id: id))
  end
end
