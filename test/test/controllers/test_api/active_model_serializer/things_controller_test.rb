require_relative '../../base'

if defined?(ActiveModel::Serializer)
  class TestApi::ActiveModelSerializer::ThingsControllerTest < ActionController::TestCase
    def test_list
      get :index, as: :json
      assert_response :success
      assert parsed_body[0]['name']
      assert parsed_body[0]['owner']
      assert_nil parsed_body[0]['calculated_property']
    end

    def test_show
      get :show, as: :json, params: {id: things(:thing_1).id}
      assert_response :success
      assert parsed_body['owner']
    end
  end
end
