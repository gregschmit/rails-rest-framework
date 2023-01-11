class DemoApi::RootController < DemoApiController
  self.extra_actions = {nil: :get, blank: :get, echo: :post}

  def root
    api_response({message: "Welcome to the Rails REST Framework Demo API."})
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
