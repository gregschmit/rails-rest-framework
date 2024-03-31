# Check for best practices at: https://github.com/rails/rails, file:
# `railties/lib/rails/generators/rails/app/templates/config/puma.rb.tt`.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

rails_env = ENV.fetch("RAILS_ENV", "development")
environment rails_env

case rails_env
when "production"
  workers_count = Integer(ENV.fetch("WEB_CONCURRENCY", 1))
  workers(workers_count) if workers_count > 1

  preload_app!
when "development"
  worker_timeout(3600)
end

port ENV.fetch("PORT", 3000)
