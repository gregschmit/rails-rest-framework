require "test_helper"

if defined?(ActiveModel::Serializer)
  class TestApi::ActiveModelSerializer::ThingsControllerTest < ActionController::TestCase
    def test_list
      Thing.create!(name: "test", owner_attributes: {login: "test"})
      get(:index, as: :json)
      assert_response(:success)
      assert(@response.parsed_body[0]["name"])
      assert(@response.parsed_body[0]["owner"])
      assert_equal("working!", @response.parsed_body[0]["test_serializer_method"])
      assert_nil(@response.parsed_body[0]["calculated_property"])
    end

    def test_show
      t = Thing.create!(name: "test", owner_attributes: {login: "test"})
      get(:show, as: :json, params: {id: t.id})
      assert_response(:success)
      assert(@response.parsed_body["owner"])
    end
  end
end
