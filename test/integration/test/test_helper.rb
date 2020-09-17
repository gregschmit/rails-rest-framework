ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require "minitest/pride"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
end
