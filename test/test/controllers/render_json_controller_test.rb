require "test_helper"

if defined?(ActiveModel::Serializer)
  class RenderJsonControllerTest < ActionController::TestCase
    def test_list_rest_serializer
      get(:list_rest_serializer)
      assert_response(:success)
    end

    def test_list_am_serializer
      get(:list_am_serializer)
      assert_response(:success)
    end

    def test_show_rest_serializer
      get(:show_rest_serializer, params: { id: User.first.id })
      assert_response(:success)
    end

    def test_show_am_serializer
      get(:show_am_serializer, params: { id: User.first.id })
      assert_response(:success)
    end
  end
end
