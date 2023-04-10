Rails.application.routes.draw do
  rest_root

  namespace :plain_api do
    rest_root
    rest_resources :emails
    rest_resources :genres
    rest_resources :marbles
    rest_resources :movies
    rest_resources :phone_numbers
    rest_resources :users
  end

  namespace :demo_api do
    rest_root
    rest_resources :emails
    rest_resources :genres
    rest_resources :marbles
    rest_resources :movies
    rest_resources :phone_numbers
    rest_resources :users do
      rest_resources :marbles
      rest_resources :movies
    end
  end

  rest_root :test_api
  namespace :test_api do
    rest_resource :user do
      rest_resources :marbles
    end
    rest_resources :marbles
    rest_resources :read_only_marbles
    rest_resources :marbles_with_added_select
    rest_resources :marbles_with_bare_create, force_plural: true, only: [:create]
    rest_resources :marbles_with_fields_hash
    rest_resources :marbles_with_string_serializer
    rest_resources :marbles_without_rescue_unknown_format
    rest_resource :marble, force_singular: true

    rest_route :network

    if defined?(ActiveModel::Serializer)
      namespace :active_model_serializer do
        rest_resources :marbles
      end
    end
  end

  if defined?(ActiveModel::Serializer)
    rest_resources :render_json
  end
end
