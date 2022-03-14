require_relative "base"

class DemoApi::ThingsControllerTest < ActionController::TestCase
  include BaseDemoApiControllerTests

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}

  def test_destroy_aborted
    t = Thing.create!(name: "Undestroyable")
    delete(:destroy, as: :json, params: {id: t.id})
    assert_response(406)
  end

  def test_update_validation_failed
    t = Thing.create!(name: "test")
    patch(:update, as: :json, params: {id: t.id}, body: {price: -1}.to_json)
    assert_response(400)
  end
end
