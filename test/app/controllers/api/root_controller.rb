class Api::RootController < ApiController
  include RESTFramework::BaseControllerMixin

  self.extra_actions = {
    dev_test: :get,
    ip: :get,
    c: {
      methods: [:get, :post],
      metadata: {gns: 5},
    },
  }

  def root
    render_api(
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
    render_api(
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
      render_api({message: "Console not available."})
    end

    render_api({message: "Console opened."})
  end
end
