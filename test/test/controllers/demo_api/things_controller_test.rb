require_relative "base"

class DemoApi::ThingsControllerTest < ActionController::TestCase
  include BaseDemoApiControllerTests

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}

  def test_destroy_aborted
    t = Thing.create!(name: "Undestroyable")
    delete(:destroy, as: :json, params: {id: t.id})
    assert_response(400)
  end

  def test_update_validation_failed
    t = Thing.create!(name: "test")
    patch(:update, as: :json, params: {id: t.id}, body: {price: -1}.to_json)
    assert_response(400)
  end

  def test_create_failed
    post(:create, as: :json, body: {some_column: "should fail"}.to_json)
    assert_response(400)
    assert(@response.parsed_body.key?("message"))
  end

  def test_except_columns
    # Test to make sure this controller normally has a `name` field.
    get(:index, as: :json)
    assert_response(:success)
    assert(@response.parsed_body[0].key?("name"))

    # Adding `name` to `except` param should remove the attribute.
    get(:index, as: :json, params: {except: "name"})
    assert_response(:success)
    refute(@response.parsed_body[0].key?("name"))
  end

  def test_only_columns
    # Test to make sure this controller normally has a `name` field.
    get(:index, as: :json)
    assert_response(:success)
    assert(@response.parsed_body[0].keys.length > 2)

    # Adding `name` to `except` param should remove the attribute.
    get(:index, as: :json, params: {only: "id,name"})
    assert_response(:success)
    assert_equal(["id", "name"].sort, @response.parsed_body[0].keys.sort)
  end
end
