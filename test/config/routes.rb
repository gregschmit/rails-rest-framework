Rails.application.routes.draw do
  # API1
  rest_root :api1
  namespace :api1 do
    rest_resources :things
    rest_resources :users
  end

  # API2
  namespace :api2 do
    rest_root
    rest_resource :user
    rest_resources :things
    rest_resources :read_only_things
    rest_resources :things_with_bare_create, force_plural: true, only: [:create]
    rest_resource :thing, force_singular: true

    rest_route :network
  end
end
