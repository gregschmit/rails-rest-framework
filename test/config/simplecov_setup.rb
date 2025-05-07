require "simplecov"

# Initialize Coveralls only for main test and when in CI pipeline.
IS_MAIN_RUBY = File.read(File.expand_path("../../.ruby-version", __dir__)).strip.match?(
  RUBY_VERSION,
)
IS_MAIN_RAILS = ENV["RAILS_VERSION"]&.match?(
  File.read(File.expand_path("../../.rails-version", __dir__)).strip,
)
if IS_COVERALLS = IS_MAIN_RUBY && IS_MAIN_RAILS && ENV["CI"]
  puts("Configuring SimpleCov output for submission to `coveralls.io`.")
else
  puts("Configuring SimpleCov output for HTML viewing.")
end

# Configure SimpleCov.
SimpleCov.start do
  minimum_coverage 10

  # The `rest_framework` project directory should be the root for coverage purposes.
  root ".."
  coverage_dir "reports/coverage"

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
