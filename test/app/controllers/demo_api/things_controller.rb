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

  class Channel < ApplicationCable::Channel
    # Subscribe with:
    # {"command": "subscribe","identifier": "{\"channel\": \"DemoApi::ThingsController::Channel\"}"}
    def subscribed
      logger.info("GNS: subscribed")
      stream_from("demo_api/things")
    end

    def index(_data)
      controller = self._controller.new
      controller.request = ActionDispatch::Request.new({})
      controller.request.format
      controller.index
      ActionCable.server.broadcast(
        "demo_api/things",
        self._controller.get_serializer_class.new(self._controller.get_recordset).serialize,
      )
    end

    def _controller
      return self.class.to_s.deconstantize.constantize
    end
  end

  this_controller = self
  Thing.define_method(:bcast) {
    if self.in?(controller.get_recordset)
      ActionCable.server.broadcast(
        "demo_api/things",
        this_controller.get_serializer_class.new(self).serialize,
      )
    end
  }
  Thing.after_commit(:bcast)
  # Thing.after_commit do
  #   ActionCable.server.broadcast(
  #     "demo_api/things",
  #     this_controller.get_serializer_class.new(self).serialize,
  #   )
  # end
end
