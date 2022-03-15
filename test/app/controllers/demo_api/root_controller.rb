class DemoApi::RootController < DemoApiController
  self.extra_actions = {nil: :get, blank: :get}

  def root
    api_response({message: "Welcome to the Rails REST Framework Demo API."})
  end

  def nil
    api_response(nil)
  end

  def blank
    api_response("")
  end
end
