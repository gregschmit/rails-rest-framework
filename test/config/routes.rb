Rails.application.routes.draw do
  root to: redirect("/demo_api")

  namespace :demo_api do
    rest_root
    rest_resources :things
    rest_resources :users do
      rest_resources :things
    end
  end

  rest_root :test_api
  namespace :test_api do
    rest_resource :user do
      rest_resources :things
    end
    rest_resources :things
    rest_resources :read_only_things
    rest_resources :things_with_added_select
    rest_resources :things_with_bare_create, force_plural: true, only: [:create]
    rest_resources :things_with_fields_hash
    rest_resources :things_with_string_serializer
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
