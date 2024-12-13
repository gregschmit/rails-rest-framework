require "test_helper"

if defined?(ActiveModel::Serializer)
  class Api::Test::ActiveModelSerializer::UsersControllerTest < ActionController::TestCase
    def test_list
      User.create!(login: "test", manager_attributes: {login: "test2"})
      get(:index, as: :json)
      assert_response(:success)
      assert(@response.parsed_body[0]["login"])
      assert(@response.parsed_body[0]["manager"])
      assert_equal("working!", @response.parsed_body[0]["test_serializer_method"])
      assert_nil(@response.parsed_body[0]["calculated_property"])
    end

    def test_show
      t = User.create!(login: "test", manager_attributes: {login: "test2"})
      get(:show, as: :json, params: {id: t.id})
      assert_response(:success)
      assert(@response.parsed_body["manager"])
    end
  end
end
