source "https://rubygems.org"

# https://yehudakatz.com/2010/12/16/clarifying-the-roles-of-the-gemspec-and-gemfile/
gemspec

# Support testing against multiple Rails versions.
RAILS_VERSION = Gem::Version.new(
  ENV["RAILS_VERSION"] || File.read(File.expand_path(".rails-version", __dir__)).strip,
)
gem "rails", "~> #{RAILS_VERSION}"

# Development & Testing
gem "byebug"
gem "coveralls", require: false
gem "minitest", ">= 5.0"
gem "pry-rails"
gem "rake", ">= 12.0"
gem "rubocop-shopify", require: false
gem "sqlite3", "~> 1.4.0"
gem "web-console", require: false

# Ruby 3 removed webrick, so we need to install it manually.
if Gem::Version.new(RUBY_VERSION) > Gem::Version.new("3")
  gem "webrick"
end

# Include gem active_model_serializers so we can test against their interface (Rails 6 only).
if RAILS_VERSION < Gem::Version.new("7") && RAILS_VERSION >= Gem::Version.new("6")
  gem "active_model_serializers", "0.10.13"
end

# Documentation: Only use if requested via environment variable `RRF_DOCS`.
if ENV["RRF_DOCS"]
  gem "github-pages", ">= 208"
  gem "yard"
end
