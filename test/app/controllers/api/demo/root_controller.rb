class Api::Demo::RootController < Api::DemoController
  self.extra_actions = {nil: :get, blank: :get, echo: :post}

  def root
    api_response({message: Api::DemoController::DESCRIPTION})
  end

  def nil
    api_response(nil)
  end

  def blank
    api_response("")
  end

  def echo
    api_response({message: "Here is your data:", data: request.request_parameters})
  end

  def secret_key_base
    api_response({secret_key_base: Rails.application.secret_key_base})
  end
end
