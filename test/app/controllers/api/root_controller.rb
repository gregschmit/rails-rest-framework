class Api::RootController < ApiController
  include RESTFramework::BaseControllerMixin

  self.extra_actions = {dev_test: :get, ip: :get, c: [:get, :post]}

  def root
    return api_response(
      {
        message: "This is the test app for Rails REST Framework. There are three APIs:",
        plain_api: {
          message: Api::PlainController.description,
          url: api_plain_root_url,
        },
        demo_api: {
          message: Api::DemoController.description,
          url: api_demo_root_url,
        },
        test_api: {
          message: Api::TestController.description,
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
        x_forwarded_for: request.headers["HTTP_X_FORWARDED_FOR"],
        cf_connecting_ip: request.headers["HTTP_CF_CONNECTING_IP"],
      },
    )
  end

  def c
    begin
      console
    rescue NameError
      return api_response({message: "Console not available."})
    end

    return api_response({message: "Console opened."})
  end
end
