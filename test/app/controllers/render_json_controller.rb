if defined?(ActiveModel::Serializer)
  class RenderJsonController < ApplicationController
    include RESTFramework::BaseModelControllerMixin

    self.extra_actions = {list_rest_serializer: :get, list_am_serializer: :get}
    self.extra_member_actions = {show_rest_serializer: :get, show_am_serializer: :get}
    self.model = User

    def list_rest_serializer
      @users = self.get_recordset
      render(json: @users, each_serializer: Api::Test::UsersController::UsersSerializer)
    end

    def list_am_serializer
      @users = self.get_recordset
      render(json: @users, each_serializer: UserSerializer)
    end

    def show_rest_serializer
      @user = self.get_record
      render(json: @user, serializer: Api::Test::UsersController::UsersSerializer)
    end

    def show_am_serializer
      @user = self.get_record
      render(json: @user, serializer: UserSerializer)
    end
  end
end
