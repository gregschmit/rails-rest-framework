require "test_helper"

if defined?(ActiveModel::Serializer)
  class TestApi::ActiveModelSerializer::ThingsControllerTest < ActionController::TestCase
    def test_list
      Thing.create!(name: "test", owner_attributes: {login: "test"})
      get(:index, as: :json)
      assert_response(:success)
      assert(parsed_body[0]["name"])
      assert(parsed_body[0]["owner"])
      assert_nil(parsed_body[0]["calculated_property"])
    end

    def test_show
      t = Thing.create!(name: "test", owner_attributes: {login: "test"})
      get(:show, as: :json, params: {id: t.id})
      assert_response(:success)
      assert(parsed_body["owner"])
    end
  end
end
