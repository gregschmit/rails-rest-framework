if defined?(ActiveModel::Serializer)
  class RenderJsonController < ApplicationController
    include RESTFramework::BaseModelControllerMixin

    self.extra_actions = {list_rest_serializer: :get, list_am_serializer: :get}
    self.extra_member_actions = {show_rest_serializer: :get, show_am_serializer: :get}
    self.model = Marble

    def list_rest_serializer
      @marbles = self.get_recordset
      render(json: @marbles, each_serializer: Api::Test::MarblesController::MarblesSerializer)
    end

    def list_am_serializer
      @marbles = self.get_recordset
      render(json: @marbles, each_serializer: MarbleSerializer)
    end

    def show_rest_serializer
      @marble = self.get_record
      render(json: @marble, serializer: Api::Test::MarblesController::MarblesSerializer)
    end

    def show_am_serializer
      @marble = self.get_record
      render(json: @marble, serializer: MarbleSerializer)
    end
  end
end
