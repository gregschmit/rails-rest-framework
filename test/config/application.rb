require_relative "boot"
require "uri"

require "rails/all"

# Require `sprockets` if testing asset pipeline.
if ENV["ASSET_PIPELINE"] == "sprockets"
  require "sprockets/railtie"
end

# Patch for Ransack (fixes `undefined method 'table_name' for #<Arel::Table`).
class Arel::Table
  def table_name
    return self.name
  end
end

# Require the gems listed in Gemfile.
Bundler.require(*Rails.groups)

class Application < Rails::Application
  if Rails::VERSION::MAJOR >= 7
    config.load_defaults(7.0)
  end

  config.x.trusted_ip = "199.27.253.42"

  config.hosts = nil

  config.autoloader = :zeitwerk
  config.eager_load = false

  if Rails::VERSION::MAJOR >= 7 && Rails::VERSION::MINOR >= 1
    config.action_dispatch.show_exceptions = Rails.env.test? ? :none : :all
  else
    config.action_dispatch.show_exceptions = !Rails.env.test?
  end

  config.consider_all_requests_local = !Rails.env.production?
  config.serve_static_files = true

  config.cache_classes = false
  config.action_controller.perform_caching = false

  config.active_storage.service = :local

  config.session_store(:cookie_store, key: "rrf_session")

  config.cache_store = :memory_store, {size: 64.megabytes}

  if defined?(Bullet)
    config.after_initialize do
      Bullet.enable = true
      # Bullet.alert = true
      Bullet.counter_cache_enable = false
      Bullet.console = true
      Bullet.add_footer = true
      Bullet.raise = true if Rails.env.test?
    end
  end

  if defined?(MissionControl)
    config.mission_control.jobs.base_controller_class = "JobsController"
  end

  if defined?(SolidQueue)
    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.connects_to = {database: {writing: :solid_queue, reading: :solid_queue}}
  end

  if defined?(WebConsole)
    config.web_console.permissions = config.x.trusted_ip
    config.web_console.development_only = false
  end

  RESTFramework.config.freeze_config = true

  # Use vendored assets if testing `sprockets` or `propshaft`.
  if ENV["ASSET_PIPELINE"] == "sprockets" || ENV["ASSET_PIPELINE"] == "propshaft"
    RESTFramework.config.use_vendored_assets = true
  end

  if Rails::VERSION::MAJOR == 7 && Rails::VERSION::MINOR < 1
    config.active_record.legacy_connection_handling = false
    config.active_support.remove_deprecated_time_with_zone_name = true
  end
end
