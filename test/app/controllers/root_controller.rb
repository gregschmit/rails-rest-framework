class RootController < ApplicationController
  include RESTFramework::BaseControllerMixin

  self.extra_actions = {dev_test: :get}

  def root
    return api_response(
      {
        message: "This is the test app for Rails REST Framework. There are three APIs:",
        plain_api: {
          message: PlainApiController::DESCRIPTION,
          url: plain_api_root_url,
        },
        demo_api: {
          message: DemoApiController::DESCRIPTION,
          url: demo_api_root_url,
        },
        test_api: {
          message: TestApiController::DESCRIPTION,
          url: test_api_url,
        },
      },
    )
  end
end
