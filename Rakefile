require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new :test do |t|
  t.description = "Run entire test suite"
  t.libs << "test"
  t.libs << "lib"
  t.pattern = 'test/**/*_test.rb'
end

task :default => :test

# Add helpers for unit and integration tests.
namespace :test do
  Rake::TestTask.new :unit do |t|
    t.description = "Run unit test suite"
    t.libs << "test"
    t.libs << "lib"
    t.pattern = 'test/unit/**/*_test.rb'
  end

  Rake::TestTask.new :integration do |t|
    t.description = "Run integration test suite"
    t.libs << "test"
    t.libs << "lib"
    t.pattern = 'test/integration/**/*_test.rb'
  end
end
