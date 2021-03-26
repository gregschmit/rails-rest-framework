ENV['RAILS_ENV'] ||= 'test'

# Initialize SimpleCov before including application code.
require 'simplecov'

# Initialize Coveralls only for main Travis test.
is_main_travis_ruby = File.read(File.expand_path("../../.ruby-version", __dir__)).strip.match?(
  RUBY_VERSION
)
is_main_travis_rails = ENV['RAILS_VERSION']&.match?(
  File.read(File.expand_path("../../.rails-version", __dir__)).strip
)
is_main_travis_env = is_main_travis_ruby && is_main_travis_rails
require 'coveralls' if is_main_travis_env

# Configure SimpleCov/Coveralls.
SimpleCov.start 'rails' do
  minimum_coverage 10

  # Only upload to Coveralls for primary Travis test; otherwise use HTML formatter.
  if is_main_travis_env
    formatter Coveralls::SimpleCov::Formatter
  else
    formatter SimpleCov::Formatter::HTMLFormatter
  end

  # Filter test directory and documentation.
  add_filter 'test/'
  add_filter 'doc/'
  add_filter 'docs/'
end

require_relative '../config/environment'

require 'minitest/pride'
require 'rails/test_help'


class ActiveSupport::TestCase
  # Load all fixtures.
  fixtures :all

  # Run tests in parallel for Rails >=6.
  if Rails::VERSION::MAJOR >= 6
    parallelize(workers: :number_of_processors)
  end

  # Helper to get parsed (json) body for both old and new Rails.
  def _parsed_body
    if Rails::VERSION::MAJOR >= 6
      return @response.parsed_body
    else
      return JSON.parse(@response.parsed_body)
    end
  end
end
