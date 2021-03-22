ENV['RAILS_ENV'] ||= 'test'

# Initialize SimpleCov/Coveralls before including application code.
require 'simplecov'
require 'coveralls'
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
#SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter  # for development
SimpleCov.start do
  minimum_coverage 10

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
end
