require "bundler/gem_tasks"
require "rake/testtask"

require "rails"

require 'fileutils'
TEST_APP_ROOT = File.expand_path('test', __dir__)

Rake::TestTask.new :test do |t|
  # Setup test database.
  FileUtils.chdir TEST_APP_ROOT do
    puts "\n== Loading Schema =="
    system('bundle exec rake db:schema:load')
  end

  # Define test parameters.
  t.description = "Prepare and run the test suite."
  t.pattern = 'test/test/**/*.rb'
end

task :default => :test
