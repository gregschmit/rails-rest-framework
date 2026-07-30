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

  rest_route :api

  namespace :api do
    rest_route :demo
    namespace :demo do
      rest_route :emails, :genres, :movies, :phone_numbers
      rest_route :users do
        rest_route :movies
      end
    end

    rest_route :test
    namespace :test do
      rest_route :user, :users
      resources :users, only: [] do
        rest_route :user_emails
      end

      rest_route(
        :added_select,
        :bare_create,
        :fields_hash_except,
        :fields_hash_exclude,
        :fields_hash_only,
        :fields_hash_only_except,
        :no_rescue_unknown_format,
        :read_only,
        :users_with_hidden,
        :find_by,
        :users_with_association_fields,
        :unpaginated,
        :no_total_count,
      )

      rest_route :network

      # Isolated namespace for the association-expansion feature: the parent controller and the
      # sibling it discovers are both under `assoc_exp`, so they don't collide with the real
      # `Api::Test::UsersController`.
      namespace :assoc_exp do
        rest_route :users, :users_explicit, :users_disabled, :movies, :genres
        rest_route :limits, :limits_per_assoc, :limits_disabled, :limits_unlimited
      end

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
