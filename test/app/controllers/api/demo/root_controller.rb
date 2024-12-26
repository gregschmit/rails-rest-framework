class Api::Demo::RootController < Api::DemoController
  self.description = Api::DemoController::DESCRIPTION
  self.extra_actions = {nil: :get, blank: :get, echo: :post}
  self.openapi_include_children = true

  def root
    render_api({message: Api::DemoController.description})
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
