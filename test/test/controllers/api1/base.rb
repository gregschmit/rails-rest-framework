require_relative '../base'


# Common tests for all controllers.
module BaseApi1ControllerTests
  def self.included(base)
    base.class_attribute :create_params
    base.class_attribute :update_params
  end

  def _get_model
    return self.class.name.match(/([a-zA-Z]+)ControllerTest$/)[1].singularize.constantize
  end

  def test_can_hit_index
    get :index
    assert_response :success

    [:json, :xml].each do |fmt|
      get :index, format: fmt
      assert_response :success
    end
  end

  def test_create
    model = self._get_model
    post :create, format: :json, as: :json, params: self.class.create_params
    assert_response :success
    assert model.find_by(id: @response.parsed_body["id"])
  end

  def test_update
    model = self._get_model
    record = model.first

    # Check old properties aren't the same as the new ones we're assigning in update.
    assert self.class.update_params.map { |k,v| record.send(k) != v }.all?

    patch :update, format: :json, as: :json, params: {id: record.id}, body: self.class.update_params.to_json
    assert_response :success

    # Ensure properties are updated.
    record.reload
    assert self.class.update_params.map { |k,v| record.send(k) == v }.all?
  end

  def test_destroy
    model = self._get_model
    id = model.first.id
    delete :destroy, params: {id: id}
    assert_response :success
    assert_nil model.find_by(id: id)
  end
end
