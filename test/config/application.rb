require_relative "boot"
require "uri"

# Rather than `require 'rails/all'`, only require things we absolutely need.
require "rails"
[
  "active_record/railtie",
  "action_controller/railtie",
  "action_view/railtie",
  "active_job/railtie",
  "rails/test_unit/railtie",
].each do |railtie|
  require railtie
end

# Sprockets was removed in Rails 7.
if USE_SPROCKETS = (Rails::VERSION::MAJOR < 7)
  require "sprockets/railtie"
end

# Require the gems listed in Gemfile.
Bundler.require(*Rails.groups)

class Application < Rails::Application
  config.autoloader = :zeitwerk
  config.eager_load = false

  config.action_dispatch.show_exceptions = !Rails.env.test?
  config.consider_all_requests_local = true
  config.serve_static_files = true

  config.cache_classes = false
  config.action_controller.perform_caching = false

  if USE_SPROCKETS
    config.assets.debug = false
    config.assets.check_precompiled_asset = false
  end

  config.session_store(:cookie_store, key: "_session")
  config.secret_token = "a_test_token"
  config.secret_key_base = "a_test_secret"

  config.logger = Logger.new($stdout)
  config.log_level = :warn
end
