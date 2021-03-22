require "rails/test_unit/runner"

require 'fileutils'
TEST_APP_ROOT = File.expand_path('test', __dir__)

desc "Prepare and run the test suite."
task :test do |t|
  # Setup test database.
  FileUtils.chdir TEST_APP_ROOT do
    puts "\n== Loading Schema =="
    system('bundle exec rake db:schema:load')
  end

  # Run tests.
  Rails::TestUnit::Runner.rake_run(["test/test"])
end

task :default => :test
