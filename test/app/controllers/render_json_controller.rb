if defined?(ActiveModel::Serializer)
  class RenderJsonController < ApplicationController
    include RESTFramework::BaseModelControllerMixin

    self.extra_actions = {list_rest_serializer: :get, list_am_serializer: :get}
    self.extra_member_actions = {show_rest_serializer: :get, show_am_serializer: :get}
    self.model = Thing

    def list_rest_serializer
      @things = self.get_recordset
      render(json: @things, each_serializer: TestApi::ThingsController::ThingsSerializer)
    end

    def list_am_serializer
      @things = self.get_recordset
      render(json: @things, each_serializer: ThingSerializer)
    end

    def show_rest_serializer
      @thing = self.get_record
      render(json: @thing, serializer: TestApi::ThingsController::ThingsSerializer)
    end

    def show_am_serializer
      @thing = self.get_record
      render(json: @thing, serializer: ThingSerializer)
    end
  end
end
