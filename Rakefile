require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

# Add helpers for unit and app tests.
namespace :test do
  desc "run integration tests"
  task :integration do
    Dir.glob(File.expand_path("test/integration/**/*_test.rb", __dir__)) { |f| load(f) }
  end

  namespace :integration do
    [:app1, :app2].each do |a|
      desc "run sample #{a} integration tests"
      task a do
        Dir.glob(File.expand_path("test/integration/#{a}/**/*_test.rb", __dir__)) { |f| load(f) }
      end

      namespace a do
        desc "run sample #{a}"
        task :run, :port do |t, args|
          args.with_defaults(port: 3000)
          require_relative "test/integration/#{a}/app.rb"
          Rack::Handler::WEBrick.run(App, Host: '127.0.0.1', Port: args[:port].to_s)
        end

        desc "console to sample #{a}"
        task :console, :port do |t, args|
          require 'irb'
          args.with_defaults(port: 3000)
          require_relative "test/integration/#{a}/app.rb"
          binding.irb
        end
      end
    end
  end

  desc "run unit tests"
  task :unit do
    Dir.glob(File.expand_path("test/unit/**/*_test.rb", __dir__)) { |f| load(f) }
  end
end
