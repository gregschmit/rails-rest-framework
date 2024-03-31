# Before booting, remove `server.pid` (fixes issue in production where the app reboots constantly
# with: `A server is already running. Check /app/test/tmp/pids/server.pid.`).
require "fileutils"
FileUtils.rm_rf("tmp/pids/server.pid")

# Set up gems listed in the Gemfile.
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __dir__)
require "bundler/setup"

# Starting at Rails 7.1, we had to start requiring simplecov here to ensure it was loaded prior to
# the lib/application code.
if ARGV[0] == "test"
  require_relative "simplecov_setup"
end
