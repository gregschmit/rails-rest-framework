require 'rails'
require 'active_record'
require 'action_controller/railtie'
require 'rails/test_help'

require 'rest_framework'

require_relative '../models'
require_relative 'controllers'

# Load into SQLite3 database.
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: "../db/test.sqlite3"
load(File.expand_path("../db/schema.rb", __dir__))

# Define the application.
class App1 < Rails::Application
  config.session_store :cookie_store, :key => '_session'
  config.secret_token = 'a_test_token'
  config.secret_key_base = 'a_test_secret'

  Rails.logger = nil  # Logger.new($stdout)

  routes.draw do
    rest_root :api
    namespace :api do
      rest_resources :things
    end
  end
end
