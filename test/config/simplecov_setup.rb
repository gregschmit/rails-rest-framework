# Coverage tooling is only bundled on the official Ruby/Rails (see `Gemfile`), so it may be absent.
begin
  require "simplecov"
rescue LoadError
  # Nothing to configure without SimpleCov.
end

if defined?(SimpleCov)
  # Submit to coveralls in CI; otherwise generate an HTML report for local viewing.
  if IS_COVERALLS = ENV["CI"]
    puts("Configuring SimpleCov output for submission to `coveralls.io`.")
  else
    puts("Configuring SimpleCov output for HTML viewing.")
  end

  SimpleCov.start do
    minimum_coverage 10

    # The `rest_framework` project directory should be the root for coverage purposes.
    root ".."
    coverage_dir "test/public/reports/coverage"

    # Filter out everything but the lib directory.
    skip "app/"
    skip "bin/"
    skip "docs/"
    skip "test/"

    # Submit to `coveralls.io` if configured, otherwise write an HTML report.
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
end
