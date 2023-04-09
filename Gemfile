source "https://rubygems.org"

# Stamp version before packaging.
# RESTFramework::Version.stamp_version
begin
  system("echo 'gns: testing git inside gemfile:'")
  system("git status")
end

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
gem "rake", ">= 12.0"

# Ruby 3 removed webrick, so we need to install it manually.
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3")
  gem "webrick"
end

# Include `active_model_serializers` for custom integration (Rails >=6 only).
if RAILS_VERSION > Gem::Version.new("6")
  gem "active_model_serializers", "0.10.13"
end

# Include `translate_enum` for custom integration.
gem "translate_enum"

group :development do
  gem "annotate"
  gem "better_errors"
  gem "binding_of_caller"
  gem "byebug"
  gem "pry-rails"
  gem "rubocop-shopify", require: false
  gem "web-console"

  # Profiling
  gem "rack-mini-profiler"
  gem "stackprof"
end

group :test do
  gem "minitest", ">= 5.0"
  gem "simplecov"
  gem "simplecov-lcov", "0.8.0", require: false
end

group :development, :test do
  # Heroku does not allow sqlite3 gem.
  gem "sqlite3", "~> 1.4.0"
end

group :production do
  # Heroku requires Postgres.
  gem "pg"
end
