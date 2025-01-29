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

    # In Rails <8, `assert_response` will end up calling `@response.body` to precalculate a
    # message, which is kinda stupid given that `assert_response` should only check the status
    # code. However, this behavior is triggered by use of the `api` renderer with blank responses,
    # so it might be related to the fact that the `api` renderer uses `head` for returning blank
    # responses, but using the renderer means that `render` is called, causing this issue.
    #
    # This is the exception:
    #   TypeError: no implicit conversion of true into String
    #     actionpack (7.2.1.2) lib/action_dispatch/http/response.rb:117:in `block in body'
    #     actionpack (7.2.1.2) lib/action_dispatch/http/response.rb:155:in `each'
    #     actionpack (7.2.1.2) lib/action_dispatch/http/response.rb:155:in `each_chunk'
    #     actionpack (7.2.1.2) lib/action_dispatch/http/response.rb:137:in `each'
    #     actionpack (7.2.1.2) lib/action_dispatch/http/response.rb:117:in `body'
    #     actionpack (7.2.1.2) lib/action_dispatch/http/response.rb:331:in `body'
    #     actionpack (7.2.1.2) lib/action_dispatch/testing/assertions/response.rb:95:in `response_body_if_short'
    #     actionpack (7.2.1.2) lib/action_dispatch/testing/assertions/response.rb:91:in `generate_response_message'
    #     actionpack (7.2.1.2) lib/action_dispatch/testing/assertions/response.rb:34:in `assert_response'
    #     test/controllers/api/demo/root_controller_test.rb:31:in `test_blank_json'
    #     minitest (5.25.4) lib/minitest/test.rb:94:in `block (2 levels) in run'
    #     minitest (5.25.4) lib/minitest/test.rb:190:in `capture_exceptions'
    #     minitest (5.25.4) lib/minitest/test.rb:89:in `block in run'
    #     minitest (5.25.4) lib/minitest.rb:368:in `time_it'
    #     minitest (5.25.4) lib/minitest/test.rb:88:in `run'
    #     activesupport (7.2.1.2) lib/active_support/executor/test_helper.rb:5:in `block in run'
    #     activesupport (7.2.1.2) lib/active_support/execution_wrapper.rb:104:in `perform'
    #     activesupport (7.2.1.2) lib/active_support/executor/test_helper.rb:5:in `run'
    #     minitest (5.25.4) lib/minitest.rb:1208:in `run_one_method'
    #     minitest (5.25.4) lib/minitest.rb:447:in `run_one_method'
    #     minitest (5.25.4) lib/minitest.rb:434:in `block (2 levels) in run'
    #     minitest (5.25.4) lib/minitest.rb:430:in `each'
    #     minitest (5.25.4) lib/minitest.rb:430:in `block in run'
    #     minitest (5.25.4) lib/minitest.rb:472:in `on_signal'
    #     minitest (5.25.4) lib/minitest.rb:459:in `with_info_handler'
    #     minitest (5.25.4) lib/minitest.rb:429:in `run'
    #     railties (7.2.1.2) lib/rails/test_unit/line_filtering.rb:10:in `run'
    #     minitest (5.25.4) lib/minitest.rb:332:in `block in __run'
    #     minitest (5.25.4) lib/minitest.rb:332:in `map'
    #     minitest (5.25.4) lib/minitest.rb:332:in `__run'
    #     minitest (5.25.4) lib/minitest.rb:288:in `run'
    #     minitest (5.25.4) lib/minitest.rb:86:in `block in autorun'
    if Rails::VERSION::MAJOR >= 8
      assert_response(:success)
    else
      # We get around this by just manually checking the status code:
      assert_equal(204, @response.status)
    end
  end

  def test_blank_xml
    get(:blank, as: :xml)

    # See above comments (in `test_blank_json`) for explanation.
    if Rails::VERSION::MAJOR >= 8
      assert_response(:success)
    else
      assert_equal(204, @response.status)
    end
  end
end
