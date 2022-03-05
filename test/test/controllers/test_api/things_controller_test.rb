require_relative '../base'

class TestApi::ThingsControllerTest < ActionController::TestCase
  def test_list
    get :index, as: :json
    assert_response :success
    assert parsed_body['results'][0]['price']
    assert_nil parsed_body['results'][0]['shape']
  end

  def test_alternate_list
    get :alternate_list, as: :json
    assert_response :success
    assert parsed_body['results'][0]['name']
    assert_nil parsed_body['results'][0]['shape']
    assert_nil parsed_body['results'][0]['price']
  end

  def test_list_ordered_by_price
    get :index, as: :json, params: {ordering: 'price'}
    assert_response :success
    assert parsed_body['results'].first['price'].to_f < parsed_body['results'].last['price'].to_f
  end

  def test_list_ordered_by_price_reversed
    get :index, as: :json, params: {ordering: '-price'}
    assert_response :success
    assert parsed_body['results'].first['price'].to_f > parsed_body['results'].last['price'].to_f
  end

  def test_list_with_specific_page_size
    get :index, as: :json, params: {page_size: '1'}
    assert_response :success
    assert parsed_body['results'][0]['price']
    assert_nil parsed_body['results'][0]['shape']
  end

  def test_list_with_specific_page_size_page_2
    get :index, as: :json, params: {page_size: '1', page: '2'}
    assert_response :success
    assert parsed_body['results'][0]['price']
    assert_nil parsed_body['results'][0]['shape']
  end

  def test_show
    get :show, as: :json, params: {id: things(:thing_1).id}
    assert_response :success
    assert parsed_body['shape']
    assert_nil parsed_body['price']
    assert parsed_body['owner']['login']
    assert_not_nil parsed_body['owner']['is_admin']
    assert_nil parsed_body['owner']['balance']
  end

  def test_show_find_by_name
    thing = things(:thing_1)
    get :show, as: :json, params: {id: thing.name, find_by: 'name'}
    assert_response :success
    assert_equal thing.id, parsed_body['id']
    assert parsed_body['shape']
    assert_nil parsed_body['price']
    assert parsed_body['owner']['login']
    assert_not_nil parsed_body['owner']['is_admin']
    assert_nil parsed_body['owner']['balance']
  end

  def test_get_model_before_recordset
    assert @controller.send(:get_model)
  end
end
