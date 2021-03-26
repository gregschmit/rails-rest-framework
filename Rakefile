require 'rake/testtask'

require 'fileutils'
TEST_APP_ROOT = File.expand_path('test', __dir__)

desc "Load latest DB schema."
task :load_db_schema do
  FileUtils.chdir TEST_APP_ROOT do
    puts "== Loading Latest DB Schema =="
    system('bundle exec rake db:schema:load')
  end
end

Rake::TestTask.new do |t|
  t.name = :run_tests
  t.description = "Run the test suite."
  t.test_files = FileList["test/test/**/*test.rb"]
end

desc "Load the latest DB schema and run the test suite."
task :test do |t|
  Rake::Task[:load_db_schema].invoke
  Rake::Task[:run_tests].invoke
end

task default: :test
