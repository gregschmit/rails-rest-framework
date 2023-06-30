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
gem "rake", ">= 12.0"
gem "sqlite3", "~> 1.4.0"

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

gem "kramdown"
gem "kramdown-parser-gfm"

group :development do
  gem "annotate"
  gem "better_errors", "2.9.1"  # Avoid `sassc` dependency.
  gem "binding_of_caller"
  gem "byebug"
  gem "pry-rails"
  gem "rubocop-shopify", require: false
  gem "web-console"

  # Vendoring external assets.
  gem "httparty"

  # Profiling
  gem "rack-mini-profiler"
  gem "stackprof"
end

group :test do
  gem "minitest", ">= 5.0"
  gem "simplecov"
  gem "simplecov-lcov", "0.8.0", require: false
end
