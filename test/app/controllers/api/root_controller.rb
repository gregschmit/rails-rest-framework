class Api::RootController < ApiController
  include RESTFramework::BaseControllerMixin

  self.extra_actions = {dev_test: :get}

  def root
    return api_response(
      {
        message: "This is the test app for Rails REST Framework. There are three APIs:",
        plain_api: {
          message: Api::PlainController::DESCRIPTION,
          url: api_plain_root_url,
        },
        demo_api: {
          message: Api::DemoController::DESCRIPTION,
          url: api_demo_root_url,
        },
        test_api: {
          message: Api::TestController::DESCRIPTION,
          url: api_test_url,
        },
      },
    )
  end
end
