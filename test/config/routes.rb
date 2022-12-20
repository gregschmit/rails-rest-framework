Rails.application.routes.draw do
  root to: redirect("/demo_api")

  namespace :demo_api do
    rest_root
    rest_resources :things
    rest_resources :users do
      scope module: :users, as: :users do
        rest_resources :things
      end
    end
  end

  # namespace :plain_api do
  #   rest_root
  #   rest_resources :things
  #   rest_resources :users
  # end

  rest_root :test_api
  namespace :test_api do
    rest_resource :user do
      scope module: :user, as: :user do
        rest_resources :things
      end
    end
    rest_resources :things
    rest_resources :read_only_things
    rest_resources :things_with_added_select
    rest_resources :things_with_bare_create, force_plural: true, only: [:create]
    rest_resources :things_without_rescue_unknown_format
    rest_resource :thing, force_singular: true

    rest_route :network

    if defined?(ActiveModel::Serializer)
      namespace :active_model_serializer do
        rest_resources :things
      end
    end
  end

  if defined?(ActiveModel::Serializer)
    rest_resources :render_json
  end
end
