class Api2::RootController < Api2Controller
  self.extra_actions = {nil: :get, blank: :get}

  def root
    api_response({message: "Welcome to your custom API2 root!"})
  end

  def nil
    api_response(nil)
  end

  def blank
    api_response('')
  end
end
