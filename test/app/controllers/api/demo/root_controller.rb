class Api::Demo::RootController < Api::DemoController
  self.extra_actions = {nil: :get, blank: :get, echo: :post, debugging: :get}

  def root
    return api_response({message: Api::DemoController::DESCRIPTION})
  end

  def nil
    return api_response(nil)
  end

  def blank
    return api_response("")
  end

  def echo
    return api_response({message: "Here is your data:", data: request.request_parameters})
  end

  def debugging
    return api_response(
      {
        secret_key_base: Rails.application.secret_key_base,
        secret_key_base_from_credentials: Rails.application.credentials.secret_key_base,
        secret_key_base_from_env: ENV["SECRET_KEY_BASE"],
        production_key: ENV["PRODUCTION_KEY"],
      },
    )
  end
end
