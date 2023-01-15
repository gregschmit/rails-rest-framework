class DemoApi::MarblesController < DemoApiController
  include RESTFramework::ModelControllerMixin

  self.extra_member_actions = {adjust_price: :patch, toggle_is_discounted: :patch}

  def adjust_price
    self.get_record.update!(price: params[:price])
    return api_response({message: "Price updated to #{params[:price]}."})
  end

  def toggle_is_discounted
    marble = self.get_record
    marble.update!(is_discounted: !marble.is_discounted)
    return api_response({message: "Is discounted toggled to #{marble.is_discounted}."})
  end
end
