class Api::Demo::RootController < Api::DemoController
  self.description = Api::DemoController::DESCRIPTION
  self.extra_actions = {nil: :get, blank: :get, echo: :post}
  self.openapi_include_children = true

  def root
    render(api: {message: self.class.description})
  end

  def nil
    render(api: nil)
  end

  def blank
    render(api: "")
  end

  def echo
    render(api: {message: "Here is your data:", data: request.request_parameters})
  end
end
