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

  rest_resource :api

  namespace :api do
    rest_resource :demo
    namespace :demo do
      rest_resources :emails, :genres, :phone_numbers
      rest_resource :movies do
        # Nested resource without a dedicated controller: reuses the top-level
        # `Api::Demo::GenresController`, auto-scoped to `Movie.find(params[:movie_id]).genres`.
        rest_resource :genres do
          # Two levels deep: auto-scoped along the whole chain to
          # `Movie.find(movie_id).genres.find(genre_id).movies` (enforcing genre-belongs-to-movie).
          rest_resource :movies
        end
      end
      rest_resource :users do
        # Nested resource with a dedicated controller: `rest_resource` resolves the controller in
        # the current module scope, so scope the module to reach `Api::Demo::Users::MoviesController`
        # (which scopes the recordset to the user via its own `get_recordset`).
        scope(module: :users) do
          rest_resource :movies
        end
      end
    end

    rest_resource :test
    namespace :test do
      # A singular and plural user resource coexist only in this test app; both would claim the
      # `api_test_user` route helper (as they would in plain Rails), so suppress the singular's.
      rest_resource :user, helpers: false
      rest_resource :users
      resources :users, only: [] do
        rest_resource :user_emails
      end

      rest_resources(
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
        :nested_field_config,
        :users_with_association_fields,
        :unpaginated,
        :no_total_count,
      )

      rest_resource :network

      # Nested resource whose parent controller scopes its recordset: auto-scoping looks the parent
      # up through `Api::Test::Nested::MoviesController#get_recordset`, enforcing its access scope.
      namespace :nested do
        rest_resource :movies do
          rest_resource :genres
        end
      end

      # Isolated namespace for the association-expansion feature: the parent controller and the
      # sibling it discovers are both under `assoc_exp`, so they don't collide with the real
      # `Api::Test::UsersController`.
      namespace :assoc_exp do
        rest_resources :users, :users_explicit, :users_disabled, :movies, :genres
        rest_resources :limits, :limits_per_assoc, :limits_disabled, :limits_unlimited
      end

      if defined?(ActiveModel::Serializer)
        namespace :active_model_serializer do
          rest_resource :users
        end
      end
    end
  end

  if defined?(ActiveModel::Serializer)
    rest_resource :render_json
  end
end
