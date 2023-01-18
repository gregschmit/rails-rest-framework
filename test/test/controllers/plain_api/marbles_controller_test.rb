require_relative "base_crud"

class PlainApi::MarblesControllerTest < ActionController::TestCase
  include PlainApi::BaseCRUD

  self.create_params = {name: "mutation_test"}
  self.update_params = {name: "mutation_test"}

  def test_destroy_aborted
    t = Marble.create!(name: "Undestroyable")
    delete(:destroy, as: :json, params: {id: t.id})
    assert_response(400)
  end

  def test_update_validation_failed
    t = Marble.create!(name: "test")
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

  if Rails::VERSION::MAJOR >= 7
    def test_filter_by_user_id
      get(:index, as: :json, params: {"user.id": 1})
      assert_response(:success)
      assert(@response.parsed_body.all? { |t| t["user"]["id"] == 1 })
    end

    def test_filter_by_user_login
      get(:index, as: :json, params: {"user.login": "admin"})
      assert_response(:success)
      assert(@response.parsed_body.all? { |t| t["user"]["login"] == "admin" })
    end

    def test_order_by_user_id
      get(:index, as: :json, params: {ordering: "users.id"})
      assert_response(:success)
      ids = @response.parsed_body.select { |t|
              t["user"]
            }.map { |t| t["user"]["id"] }.compact.uniq
      assert_equal(ids, ids.sort)

      get(:index, as: :json, params: {ordering: "-users.id"})
      assert_response(:success)
      ids = @response.parsed_body.select { |t|
              t["user"]
            }.map { |t| t["user"]["id"] }.compact.uniq
      assert_equal(ids, ids.sort.reverse)
    end

    def test_order_by_name
      get(:index, as: :json, params: {ordering: "name"})
      assert_response(:success)
      names = @response.parsed_body.map { |t| t["name"] }.compact.uniq
      assert_equal(names, names.sort)

      get(:index, as: :json, params: {ordering: "-name"})
      assert_response(:success)
      names = @response.parsed_body.map { |t| t["name"] }.compact.uniq
      assert_equal(names, names.sort.reverse)
    end
  end
end
