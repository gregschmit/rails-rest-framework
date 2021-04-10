require_relative 'base'


class Api1::ThingsControllerTest < ActionController::TestCase
  include BaseApi1ControllerTests
  self.create_params = {name: "quicktest"}
  self.update_params = {name: "quicktest"}

  def test_destroy_failed
    id = Thing.find_by(name: 'undestroyable').id
    delete :destroy, as: :json, params: {id: id}
    assert_response 406
  end

  def test_save_failed
    id = Thing.find_by(name: 'unsaveable').id
    patch :update, as: :json, params: {id: id, body: {price: 99}.to_json}
    assert_response 406
  end
end
