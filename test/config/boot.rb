# Set up gems listed in the Gemfile.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __dir__)
require "bundler/setup"

# Starting at Rails 7.1, we had to start requiring simplecov here to ensure it was loaded prior to
# the lib/application code.
if ARGV[0] == "test"
  require_relative "simplecov_setup"
end
