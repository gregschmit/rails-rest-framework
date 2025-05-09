if defined?(Sentry) && dsn = Rails.application.credentials.sentry_dsn
  Sentry.init do |config|
    config.dsn = dsn
    config.release = "rest_framework@#{RESTFramework::VERSION}"
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

    config.enable_tracing = true
    config.traces_sample_rate = 1.0
    config.profiles_sample_rate = 1.0
  end
end
