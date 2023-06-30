require "test_helper"

if defined?(ActiveModel::Serializer)
  class Api::Test::ActiveModelSerializer::MarblesControllerTest < ActionController::TestCase
    def test_list
      Marble.create!(name: "test", user_attributes: {login: "test"})
      get(:index, as: :json)
      assert_response(:success)
      assert(@response.parsed_body[0]["name"])
      assert(@response.parsed_body[0]["user"])
      assert_equal("working!", @response.parsed_body[0]["test_serializer_method"])
      assert_nil(@response.parsed_body[0]["calculated_property"])
    end

    def test_show
      t = Marble.create!(name: "test", user_attributes: {login: "test"})
      get(:show, as: :json, params: {id: t.id})
      assert_response(:success)
      assert(@response.parsed_body["user"])
    end
  end
end
