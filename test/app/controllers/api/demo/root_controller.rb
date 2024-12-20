class Api::Demo::RootController < Api::DemoController
  self.extra_actions = {nil: :get, blank: :get, echo: :post}

  def root
    render_api({message: Api::DemoController::DESCRIPTION})
  end

  def nil
    render_api(nil)
  end

  def blank
    render_api("")
  end

  def echo
    render_api({message: "Here is your data:", data: request.request_parameters})
  end
end
