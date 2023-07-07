ENV["RAILS_ENV"] ||= "test"

# Initialize SimpleCov before including application code.
require "simplecov"

# Initialize Coveralls only for main test and when in CI pipeline.
IS_MAIN_RUBY = File.read(File.expand_path("../../.ruby-version", __dir__)).strip.match?(
  RUBY_VERSION,
)
IS_MAIN_RAILS = ENV["RAILS_VERSION"]&.match?(
  File.read(File.expand_path("../../.rails-version", __dir__)).strip,
)
if IS_COVERALLS = IS_MAIN_RUBY && IS_MAIN_RAILS && ENV["CI"]
  puts("Configured to format coverage for submission to `coveralls.io`.")
end

# Configure SimpleCov.
SimpleCov.start do
  minimum_coverage 10

  # The `rest_framework` project directory should be the root for coverage purposes.
  root ".."

  # Filter out everything but the lib directory.
  add_filter "app/"
  add_filter "bin/"
  add_filter "docs/"
  add_filter "test/"

  # Setup formatter for submission to `coveralls.io` if configured, otherwise use an HTML formatter.
  if IS_COVERALLS
    require "simplecov-lcov"

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = "../coverage/lcov.info"
    end

    formatter SimpleCov::Formatter::LcovFormatter
  else
    formatter SimpleCov::Formatter::HTMLFormatter
  end
end

require_relative "../config/environment"

# TODO: Get working? Not working now.
# Setup Bullet, if it's available.
# if defined?(Bullet)
#   module MiniTestWithBullet
#     def before_setup
#       Bullet.start_request
#       super if defined?(super)
#     end

#     def after_teardown
#       super if defined?(super)
#       Bullet.end_request
#     end
#   end

#   class ActiveSupport::TestCase
#     include MiniTestWithBullet
#   end
# end

require "rails/test_help"
