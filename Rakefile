require "bundler/gem_tasks"
require "rake/testtask"

require "rails"

require 'fileutils'
TEST_APP_ROOT = File.expand_path('test', __dir__)

Rake::TestTask.new :test do |t|
  # Setup test db.
  FileUtils.chdir TEST_APP_ROOT do
    if Rails::VERSION::MAJOR >= 6
      puts "\n== Preparing database =="
      system('bin/rails db:test:prepare')
    else
      puts "\n== Loading schema =="
      system('rake db:schema:load')
    end
  end

  # Define test parameters.
  t.description = "Prepare and run the test suite."
  t.pattern = 'test/test/**/*.rb'
end

task :default => :test
