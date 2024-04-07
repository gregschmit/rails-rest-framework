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
end
