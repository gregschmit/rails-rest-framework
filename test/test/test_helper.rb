ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

require 'minitest/pride'
require 'rails/test_help'

class ActiveSupport::TestCase
  # Run tests in parallel for Rails >=6.
  if Rails::VERSION::MAJOR >= 6
    parallelize(workers: :number_of_processors)
  end
end
