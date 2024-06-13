source "https://rubygems.org"

# We force the Gem version to "0.dev" so it doesn't keep changing inside the `Gemfile.lock`.
ENV["RRF_OVERRIDE_VERSION"] = "0.dev"
gemspec

# Support setting ruby version from env, and default to `.ruby-version` file.
ruby ENV["CUSTOM_RUBY_VERSION"] || File.read(
  File.expand_path(".ruby-version", __dir__),
).strip.split("-")[1]

# Support testing against multiple Rails versions.
RAILS_VERSION = Gem::Version.new(
  ENV["RAILS_VERSION"] || File.read(File.expand_path(".rails-version", __dir__)).strip,
)
gem "rails", "~> #{RAILS_VERSION}"
gem "rake"
gem "sqlite3", "~> 1.4"
gem "puma"

# Only Rails >=7.1 gems.
if RAILS_VERSION >= Gem::Version.new("7")
  gem "kamal"
  gem "ransack", ">= 4.0"
  gem "solid_queue"
end

# Include `active_model_serializers` for custom integration (Rails >=6 only).
if RAILS_VERSION >= Gem::Version.new("6")
  gem "active_model_serializers", "0.10.14"
end

# Include `translate_enum` for custom integration.
gem "translate_enum"

# Enable to test sprockets/propshaft.
ENV["ASSET_PIPELINE"] = nil
if ENV["ASSET_PIPELINE"] == "sprockets"
  gem "sprockets-rails"

  # Purely to test a failure in sass where if a css variable refers to a `url`, then it raises an
  # `undefined method 'size' for nil:NilClass` exception in: `sass-3.7.4/lib/sass/util.rb:157`.
  gem "sass-rails", "5.1"
elsif ENV["ASSET_PIPELINE"] == "propshaft"
  gem "propshaft"
end

if ENV["ASSET_PIPELINE"]
  # Requires an asset pipeline. Originally to schedule a periodic data wipe for demo data, however
  # that would require the worker to restart which is not currently possible in Ruby.
  # gem "mission_control-jobs"
end

gem "kramdown"
gem "kramdown-parser-gfm"

# Sentry
gem "stackprof"
gem "sentry-rails"

group :development do
  gem "better_errors", "2.9.1"  # Avoid `sassc` dependency.
  gem "binding_of_caller"
  gem "byebug"
  gem "foreman"
  gem "pry-rails"
  gem "rubocop-shopify", require: false
  gem "web-console"

  # Vendoring external assets.
  gem "httparty"

  # Profiling
  gem "rack-mini-profiler"
  gem "bullet"
end

group :test do
  gem "minitest"
  gem "simplecov", require: false
  gem "simplecov-lcov", "0.8.0", require: false
end
