require_relative "lib/rest_framework/version"

# A release build sets `RRF_STAMP_VERSION` so the version is derived from git and stamped into the
# VERSION file that ships in the gem. Otherwise stamp a stable "0.dev" so anything that resolves the
# bundle (Ruby LSP's composed bundle, editors, plain `bundle install`) never churns `Gemfile.lock`
# with `git describe` output.
rrf_version = if ENV["RRF_STAMP_VERSION"]
  RESTFramework::Version.stamp_version
else
  RESTFramework::Version.stamp_version("0.dev")
end

Gem::Specification.new do |spec|
  spec.name = "rest_framework"
  spec.version = rrf_version
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
    "VERSION",
    ".yardopts",
    *Dir["app/**/*"],
    *Dir["lib/**/*.rb"],
    *Dir["vendor/assets/**/*"],
  ]
end
