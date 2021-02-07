source "https://rubygems.org"

# https://yehudakatz.com/2010/12/16/clarifying-the-roles-of-the-gemspec-and-gemfile/
gemspec

# Allow testing against multiple Rails versions.
rails_version = ENV["RAILS_VERSION"] || "6.0"
rails_version_major = rails_version.split('.')[0].to_i
gem "rails", "~> #{rails_version}"

# Testing
gem "rake", ">= 12.0"
gem "minitest", ">= 5.0"
gem "minitest-proveit", ">= 1.0"
gem "sqlite3", "~> #{rails_version_major <= 4 ? '1.3.0' : '1.4.0'}"
gem "byebug"

# Documentation (Exclude from test environment.)
group :development do
  gem "github-pages", ">= 208"
  gem "yard"
end
