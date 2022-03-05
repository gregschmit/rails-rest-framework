require_relative 'base'

class DemoApi::ThingsControllerTest < ActionController::TestCase
  include BaseDemoApiControllerTests
  self.create_params = {name: "quicktest"}
  self.update_params = {name: "quicktest"}

  def test_destroy_failed
    id = things(:undestroyable_thing).id
    delete :destroy, as: :json, params: {id: id}
    assert_response 406
  end

  def test_save_failed
    id = things(:unsaveable_thing).id
    patch :update, as: :json, params: {id: id, body: {price: 99}.to_json}
    assert_response 406
  end
end
