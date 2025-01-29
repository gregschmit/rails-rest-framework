# Fix `uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger` from `concurrent-ruby`.
require "logger"

# Before booting, support passing production key via environment variable by writing it to disk here
# if the key file doesn't exist.
key_path = File.expand_path("credentials/production.key", __dir__)
key_value = ENV["PRODUCTION_KEY"]&.strip
if !File.file?(key_path) && key_value && !key_value.empty?
  puts "Writing #{key_path} to disk."
  File.write(key_path, key_value)
end

# Set up gems listed in the Gemfile.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __dir__)
require "bundler/setup"

# Starting at Rails 7.1, we had to start requiring simplecov here to ensure it was loaded prior to
# the lib/application code.
if ARGV[0] == "test"
  require_relative "simplecov_setup"
end
