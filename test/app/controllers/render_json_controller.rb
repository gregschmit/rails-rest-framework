if defined?(ActiveModel::Serializer)
  class RenderJsonController < ApplicationController
    include RESTFramework::Controller

    self.model = User
    remove_actions(:create, :update, :destroy, :update_all, :destroy_all)

    add_action(:list_rest_serializer, :get, type: :collection)
    add_action(:list_am_serializer, :get, type: :collection)
    add_action(:show_rest_serializer, :get, type: :member)
    add_action(:show_am_serializer, :get, type: :member)

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
