source "https://rubygems.org"

# We force the Gem version to "0.dev" so it doesn't keep changing inside the `Gemfile.lock`.
ENV["RRF_OVERRIDE_VERSION"] = "0.dev"
gemspec

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

# Include gem active_model_serializers so we can test against their interface (Rails 6 only).
if RAILS_VERSION < Gem::Version.new("7") && RAILS_VERSION >= Gem::Version.new("6")
  gem "active_model_serializers", "0.10.13"
end

group :development do
  gem "byebug"
  gem "pry-rails"
  gem "rubocop-shopify", require: false
  gem "web-console"
end

group :test do
  gem "coveralls", require: false
  gem "minitest", ">= 5.0"
end

group :development, :test do
  # Heroku does not allow sqlite3 gem.
  gem "sqlite3", "~> 1.4.0"
end

group :production do
  # Heroku requires Postgres.
  gem "pg"
end

# Documentation: Only use if requested via environment variable `RRF_DOCS`.
if ENV["RRF_DOCS"]
  gem "github-pages", ">= 208"
  gem "yard"
end
