Rails.application.routes.draw do
  # API1
  rest_root :demo_api
  namespace :demo_api do
    rest_resources :things
    rest_resources :users
  end

  # API2
  namespace :test_api do
    rest_root
    rest_resource :user
    rest_resources :things
    rest_resources :read_only_things
    rest_resources :things_with_bare_create, force_plural: true, only: [:create]
    rest_resource :thing, force_singular: true

    rest_route :network

    namespace :active_model_serializer do
      rest_resources :things
    end
  end
end
