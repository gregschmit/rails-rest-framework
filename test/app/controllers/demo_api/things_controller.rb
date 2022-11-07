class DemoApi::ThingsController < DemoApiController
  include RESTFramework::ModelControllerMixin

  self.extra_member_actions = {adjust_price: :patch, toggle_is_discounted: :patch}

  def adjust_price
    self.get_record.update!(price: params[:price])
    return api_response({message: "Price updated to #{params[:price]}."})
  end

  def toggle_is_discounted
    thing = self.get_record
    thing.update!(is_discounted: !thing.is_discounted)
    return api_response({message: "Is discounted toggled to #{thing.is_discounted}."})
  end
end
