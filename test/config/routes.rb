Rails.application.routes.draw do
  root to: "home#index"

  get "up" => "rails/health#show", as: :rails_health_check

  if defined?(MissionControl)
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  get "guide", to: "home#guide_first", format: false
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
      rest_route :emails
      rest_route :genres
      rest_route :movies
      rest_route :phone_numbers
      rest_route :users
    end

    namespace :demo do
      rest_root
      rest_route :emails
      rest_route :genres
      rest_route :movies
      rest_route :phone_numbers
      rest_route :users do
        rest_route :movies
      end
    end

    rest_root :test
    namespace :test do
      rest_route :user
      rest_route :users
      resources :users, only: [] do
        rest_route :user_emails
      end

      rest_route :added_select
      rest_route :bare_create
      rest_route :fields_hash_except
      rest_route :fields_hash_exclude
      rest_route :fields_hash_only
      rest_route :fields_hash_only_except
      rest_route :no_rescue_unknown_format
      rest_route :read_only
      rest_route :users_with_hidden
      rest_route :find_by
      rest_route :users_with_sub_fields

      rest_route :network

      if defined?(ActiveModel::Serializer)
        namespace :active_model_serializer do
          rest_route :users
        end
      end
    end
  end

  if defined?(ActiveModel::Serializer)
    rest_route :render_json
  end
end
