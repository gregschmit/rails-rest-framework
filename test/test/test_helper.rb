ENV['RAILS_ENV'] ||= 'test'

# Initialize SimpleCov before including application code.
require 'simplecov'

# Initialize Coveralls only for main Travis test.
IS_MAIN_TRAVIS_RUBY = File.read(File.expand_path("../../.ruby-version", __dir__)).strip.match?(
  RUBY_VERSION
)
IS_MAIN_TRAVIS_RAILS = ENV['RAILS_VERSION']&.match?(
  File.read(File.expand_path("../../.rails-version", __dir__)).strip
)
IS_MAIN_TRAVIS_ENV = IS_MAIN_TRAVIS_RUBY && IS_MAIN_TRAVIS_RAILS
require 'coveralls' if IS_MAIN_TRAVIS_ENV

# Configure SimpleCov.
SimpleCov.start do
  minimum_coverage 10
  command_name 'tests'

  # Only upload to Coveralls for primary Travis test; otherwise use HTML formatter.
  if IS_MAIN_TRAVIS_ENV
    formatter Coveralls::SimpleCov::Formatter
  else
    formatter SimpleCov::Formatter::HTMLFormatter
  end

  # Filter test directory and documentation.
  add_filter 'test/'
  add_filter 'doc/'
  add_filter 'docs/'
  add_filter 'app/'

  # Filter version module since it's loaded too early for SimpleCov.
  add_filter 'lib/rest_framework/version'

  add_group 'REST Framework', 'lib'
end

require_relative '../config/environment'

require 'minitest/pride'
require 'rails/test_help'


class ActiveSupport::TestCase
  # Load all fixtures.
  fixtures :all

  # Do not parallelize for now since Coveralls breaks with parallelization.
  # parallelize(workers: :number_of_processors)
end


class ActionController::TestCase
  # Expose parsed_body method on all controller tests.
  def parsed_body(reload: false)
    if reload || !defined?(@_parsed_body) || !@_parsed_body
      return @_parsed_body = begin
        if Rails::VERSION::MAJOR >= 6
          @response.parsed_body
        else
          JSON.parse(@response.parsed_body)
        end
      end
    end

    return @_parsed_body
  end
end
