class Api::RootController < ApiController
  include RESTFramework::BaseControllerMixin

  self.extra_actions = {dev_test: :get, ip: :get, c: :get}

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

  def ip
    return api_response(
      {
        ip: request.ip,
        remote_ip: request.remote_ip,
        forwarded_ip: request.headers["HTTP_X_FORWARDED_FOR"],
        cloudflare_ip: request.headers["HTTP_CF_CONNECTING_IP"],
      },
    )
  end

  def c
    console
    return api_response({message: "Console opened."})
  end
end
