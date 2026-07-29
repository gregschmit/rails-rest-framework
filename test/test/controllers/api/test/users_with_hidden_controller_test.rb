require "test_helper"

class Api::Test::UsersWithHiddenControllerTest < ActionController::TestCase
  def test_list
    get(:index, as: :json)
    assert_response(:success)
    first = @response.parsed_body[0]
    assert(first["random1"].nil?)
    assert(first["random2"].nil?)
  end

  def test_list_with_only
    get(:index, as: :json, params: { only: "random1,random2" })
    assert_response(:success)
    first = @response.parsed_body[0]
    assert(first["random1"])
    assert_not(first["random2"])
  end

  def test_list_with_include
    get(:index, as: :json, params: { include: "random1,random2" })
    assert_response(:success)
    first = @response.parsed_body[0]
    assert(first["random1"])
    assert_not(first["random2"])
  end

  def test_list_with_virtual_field_filter_returns_controlled_error
    get(:index, as: :json, params: { random1: "10" })
    assert_response(400)
    assert(@response.parsed_body["message"].present?)
  end

  def test_show
    uid = User.first.id
    get(:show, as: :json, params: { id: uid })
    assert_response(:success)
    first = @response.parsed_body
    assert(first["random1"].nil?)
  end

  def test_show_with_only
    uid = User.first.id
    get(:show, as: :json, params: { id: uid, only: "random1" })
    assert_response(:success)
    first = @response.parsed_body
    assert(first["random1"])
  end

  def test_show_with_include
    uid = User.first.id
    get(:show, as: :json, params: { id: uid, include: "random1" })
    assert_response(:success)
    first = @response.parsed_body
    assert(first["random1"])
  end
end
