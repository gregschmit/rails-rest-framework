ENV['RAILS_ENV'] ||= 'test'

# Initialize SimpleCov before including application code.
require 'simplecov'

# Initialize Coveralls only for primary Travis test.
is_default_travis_test = (
  File.read(File.expand_path("../../.ruby-version", __dir__)).match?(RUBY_VERSION) &&
  ENV['RAILS_VERSION']&.match?(File.read(File.expand_path("../../.rails-version", __dir__)))
)
puts "GNS: RUBY_VERSION: #{RUBY_VERSION}"
puts "GNS: .ruby-version: #{File.read(File.expand_path("../../.ruby-version", __dir__))}"
puts "GNS: ENV['RAILS_VERSION']: #{ENV['RAILS_VERSION']}"
puts "GNS: .rails-version: #{File.read(File.expand_path("../../.rails-version", __dir__))}"
puts "GNS: is_default_travis_test: #{is_default_travis_test}"
require 'coveralls' if is_default_travis_test

# Configure SimpleCov/Coveralls.
SimpleCov.start do
  minimum_coverage 10

  # Only upload to Coveralls for primary Travis test; otherwise use HTML formatter.
  if is_default_travis_test
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
