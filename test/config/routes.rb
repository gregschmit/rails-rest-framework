Rails.application.routes.draw do
  root to: "home#index"

  get "guide/:section", to: "home#show_guide_section", as: :show_guide_section, format: false
  get(
    "guide/:section/assets/:asset",
    to: "home#send_guide_asset",
    as: :send_guide_asset,
    format: false,
    asset: /[a-zA-Z0-9_\.-]+/,
  )

  namespace :api do
    rest_root

    namespace :plain do
      rest_root
      rest_resources :emails
      rest_resources :genres
      rest_resources :marbles
      rest_resources :movies
      rest_resources :phone_numbers
      rest_resources :users
    end

    namespace :demo do
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

    rest_root :test
    namespace :test do
      rest_resource :user do
        rest_resources :marbles
      end

      rest_resources :genres_with_fields_hash
      rest_resource :marble, force_singular: true
      rest_resources :marbles
      rest_resources :marbles_with_added_select
      rest_resources :marbles_with_bare_create, force_plural: true, only: [:create]
      rest_resources :marbles_with_fields_hash
      rest_resources :marbles_with_string_serializer
      rest_resources :marbles_with_sub_fields
      rest_resources :marbles_without_rescue_unknown_format
      rest_resources :read_only_marbles

      rest_route :network

      if defined?(ActiveModel::Serializer)
        namespace :active_model_serializer do
          rest_resources :marbles
        end
      end
    end
  end

  if defined?(ActiveModel::Serializer)
    rest_resources :render_json
  end
end
