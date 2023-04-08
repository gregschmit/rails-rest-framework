require_relative "base"

class TestApi::MarblesControllerTest < ActionController::TestCase
  include BaseTestApiControllerTests

  def test_list
    get(:index, as: :json)
    assert_response(:success)
    assert(@response.parsed_body["results"][0]["price"])
    assert_nil(@response.parsed_body["results"][0]["radius_mm"])
  end

  def test_alternate_list
    get(:alternate_list, as: :json)
    assert_response(:success)
    assert(@response.parsed_body["results"][0]["name"])
    assert_nil(@response.parsed_body["results"][0]["radius_mm"])
    assert_nil(@response.parsed_body["results"][0]["price"])
  end

  def test_list_ordered_by_price
    get(:index, as: :json, params: {ordering: "price"})
    assert_response(:success)
    assert(
      @response.parsed_body["results"].first["price"].to_f < @response.parsed_body["results"].last[
        "price"
      ].to_f,
    )
  end

  def test_list_ordered_by_price_reversed
    get(:index, as: :json, params: {ordering: "-price"})
    assert_response(:success)
    assert(
      @response.parsed_body["results"].first["price"].to_f > @response.parsed_body["results"].last[
        "price"
      ].to_f,
    )
  end

  def test_list_with_specific_page_size
    get(:index, as: :json, params: {page_size: "1"})
    assert_response(:success)
    assert(@response.parsed_body["results"][0]["price"])
    assert_nil(@response.parsed_body["results"][0]["radius_mm"])
  end

  def test_list_with_specific_page_size_page_2
    get(:index, as: :json, params: {page_size: "1", page: "2"})
    assert_response(:success)
    assert(@response.parsed_body["results"][0]["price"])
    assert_nil(@response.parsed_body["results"][0]["radius_mm"])
  end

  def test_list_except_name
    get(:index, as: :json, params: {except: "name"})
    assert_response(:success)
    assert(@response.parsed_body["results"][0]["price"])
    assert_nil(@response.parsed_body["results"][0]["name"])
  end

  def test_show
    t = Marble.create!(
      name: "test", radius_mm: 15, price: 5, user_attributes: {login: "test", is_admin: true},
    )
    get(:show, as: :json, params: {id: t.id})
    assert_response(:success)
    assert(@response.parsed_body["radius_mm"])
    refute(@response.parsed_body["price"])
    assert(@response.parsed_body["user"]["login"])
    assert(@response.parsed_body["user"]["is_admin"])
    refute(@response.parsed_body["user"]["balance"])
  end

  def test_show_find_by_name
    t = Marble.create!(name: "some weird name", radius_mm: "somemarble", price: 5)
    get(:show, as: :json, params: {id: t.name, find_by: "name"})
    assert_response(:success)
    assert_equal(t.id, @response.parsed_body["id"])
    assert(@response.parsed_body["radius_mm"])
    refute(@response.parsed_body["price"])
  end

  def test_get_model_before_recordset
    assert(@controller.class.get_model)
  end

  if Rails::VERSION::MAJOR >= 7
    def test_options
      get(:options, as: :json)
      assert_response(:success)
    end
  end

  def test_bulk_create
    post(
      :create,
      as: :json,
      params: {_json: [{name: "test_bulk_marble_1"}, {name: "test_bulk_marble_2"}]},
    )
    assert_response(:success)
    parsed_body = @response.parsed_body
    assert(parsed_body.is_a?(Array))
    assert(parsed_body.empty?)
    assert(Marble.find_by(name: "test_bulk_marble_1"))
    assert(Marble.find_by(name: "test_bulk_marble_2"))
  end

  def test_bulk_create_with_bad_insert
    post(
      :create,
      as: :json,
      params: {_json: [{name: "test_bulk_marble_1"}, {name: "test_bulk_marble_1"}]},
    )
    assert_response(:bad_request)
  end
end
