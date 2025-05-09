class Api::RootController < ApiController
  include RESTFramework::BaseControllerMixin

  self.extra_actions = {
    dev_test: :get,
    ip: :get,
    c: { methods: [ :get, :post ], metadata: { test: 5 } },
  }

  def root
    render(
      api: {
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
    render(
      api: {
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
      return render(api: { message: "Console not available." })
    end

    render(api: { message: "Console opened." })
  end
end
