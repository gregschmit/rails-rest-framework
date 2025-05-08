require "test_helper"

if defined?(ActiveModel::Serializer)
  class Api::Test::ActiveModelSerializer::UsersControllerTest < ActionController::TestCase
    def test_list
      manager = User.first
      User.create!(login: "test_ams", manager: manager)
      get(:index, as: :json, params: {ordering: "-id"})
      assert_response(:success)
      assert(@response.parsed_body[0]["login"])
      assert(@response.parsed_body[0]["manager"])
      assert_equal("working!", @response.parsed_body[0]["test_serializer_method"])
      assert_nil(@response.parsed_body[0]["calculated_property"])
    end

    def test_show
      manager = User.first
      user = User.create!(login: "test_ams", manager: manager)
      get(:show, as: :json, params: {id: user.id})
      assert_response(:success)
      assert(@response.parsed_body["manager"])
    end
  end
end
