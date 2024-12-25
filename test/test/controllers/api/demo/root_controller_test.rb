require "test_helper"

class Api::Demo::RootControllerTest < ActionController::TestCase
  def test_nil_fails
    assert_raises(RESTFramework::NilPassedToRenderAPIError) do
      get(:nil)
    end
  end

  def test_nil_json_fails
    assert_raises(RESTFramework::NilPassedToRenderAPIError) do
      get(:nil, as: :json)
    end
  end

  def test_nil_xml_fails
    assert_raises(RESTFramework::NilPassedToRenderAPIError) do
      get(:nil, as: :xml)
    end
  end

  def test_blank
    get(:blank)
    assert_response(:success)
  end

  def test_blank_json
    get(:blank, as: :json)
    assert_response(:success)
  end

  def test_blank_xml
    get(:blank, as: :xml)
    assert_response(:success)
  end
end
