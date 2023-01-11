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
  config.hosts = nil

  config.autoloader = :zeitwerk
  config.eager_load = false

  config.action_dispatch.show_exceptions = !Rails.env.test?
  config.consider_all_requests_local = true
  config.serve_static_files = true

  config.cache_classes = false
  config.action_controller.perform_caching = false

  RESTFramework.config.freeze_config = true

  if Rails::VERSION::MAJOR >= 7
    config.active_support.remove_deprecated_time_with_zone_name = true
    config.active_record.legacy_connection_handling = false
  end

  if USE_SPROCKETS
    config.assets.debug = false
    config.assets.check_precompiled_asset = false
  end

  config.session_store(:cookie_store, key: "_session")
  config.secret_token = "a_test_token"
  config.secret_key_base = "a_test_secret"
end
