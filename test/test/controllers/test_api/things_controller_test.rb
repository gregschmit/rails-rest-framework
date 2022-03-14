require_relative "base"

class TestApi::ThingsControllerTest < ActionController::TestCase
  include BaseTestApiControllerTests

  def test_list
    get(:index, as: :json)
    assert_response(:success)
    assert(@response.parsed_body["results"][0]["price"])
    assert_nil(@response.parsed_body["results"][0]["shape"])
  end

  def test_alternate_list
    get(:alternate_list, as: :json)
    assert_response(:success)
    assert(@response.parsed_body["results"][0]["name"])
    assert_nil(@response.parsed_body["results"][0]["shape"])
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
    assert_nil(@response.parsed_body["results"][0]["shape"])
  end

  def test_list_with_specific_page_size_page_2
    get(:index, as: :json, params: {page_size: "1", page: "2"})
    assert_response(:success)
    assert(@response.parsed_body["results"][0]["price"])
    assert_nil(@response.parsed_body["results"][0]["shape"])
  end

  def test_show
    t = Thing.create!(
      name: "test", shape: "test", price: 5, owner_attributes: {login: "test", is_admin: true},
    )
    get(:show, as: :json, params: {id: t.id})
    assert_response(:success)
    assert(@response.parsed_body["shape"])
    refute(@response.parsed_body["price"])
    assert(@response.parsed_body["owner"]["login"])
    assert(@response.parsed_body["owner"]["is_admin"])
    refute(@response.parsed_body["owner"]["balance"])
  end

  def test_show_find_by_name
    t = Thing.create!(name: "some weird name", shape: "something", price: 5)
    get(:show, as: :json, params: {id: t.name, find_by: "name"})
    assert_response(:success)
    assert_equal(t.id, @response.parsed_body["id"])
    assert(@response.parsed_body["shape"])
    refute(@response.parsed_body["price"])
  end

  def test_get_model_before_recordset
    assert(@controller.get_model)
  end
end
