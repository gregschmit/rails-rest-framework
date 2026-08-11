# Read the version without loading the library. Bundler evaluates this gemspec once per on-disk copy
# of the gem (e.g., both `vendor/bundle` and `vendor/cache` for a vendored git gem), so
# `require`-ing `version.rb` here would define `RESTFramework::VERSION` twice in one process and
# warn about an already-initialized constant.
version = File.read(
  File.expand_path("lib/rest_framework/version.rb", __dir__),
)[/VERSION\s*=\s*"([^"]+)"/, 1]

Gem::Specification.new do |spec|
  spec.name = "rest_framework"
  spec.version = version
  spec.authors = [ "Gregory N. Schmit" ]
  spec.email = [ "schmitgreg@gmail.com" ]

  spec.summary = "A framework for DRY RESTful APIs in Ruby on Rails."
  spec.description = "A framework for DRY RESTful APIs in Ruby on Rails."
  spec.homepage = "https://rails-rest-framework.com"
  spec.license = "MIT"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.5")

  spec.add_dependency("rails", ">= 4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/gregschmit/rails-rest-framework"

  spec.files = [
    "README.md",
    "LICENSE",
    ".yardopts",
    *Dir["app/**/*"],
    *Dir["lib/**/*.rb"],
    *Dir["vendor/assets/**/*"],
  ]
end
