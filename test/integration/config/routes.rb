Rails.application.routes.draw do
  # API1
  rest_root :api1
  namespace :api1 do
    rest_resources :things
  end

  # API2
  namespace :api2 do
    rest_root
    rest_resources :things
    rest_resources :read_only_things
    rest_resource :thing
  end
end
