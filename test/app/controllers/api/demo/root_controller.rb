class Api::Demo::RootController < Api::DemoController
  self.extra_actions = {nil: :get, blank: :get, echo: :post}

  class_attribute(:gns, default: 8)

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
    # @gns = 4
    d = [self.gns, self.class.gns]
    api_response({message: "Here is your data:", data: request.request_parameters, data2: d})
  end
end
