require_relative "lib/rest_framework/version"

# Stamp version before packaging.
RESTFramework::Version.stamp_version

Gem::Specification.new do |spec|
  spec.name = "rest_framework"
  spec.version = ENV["RRF_OVERRIDE_VERSION"] || RESTFramework::VERSION
  spec.authors = ["Gregory N. Schmit"]
  spec.email = ["schmitgreg@gmail.com"]

  spec.summary = "A framework for DRY RESTful APIs in Ruby on Rails."
  spec.description = "A framework for DRY RESTful APIs in Ruby on Rails."
  spec.homepage = "https://rails-rest-framework.com"
  spec.license = "MIT"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.add_dependency("rails", ">= 4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/gregschmit/rails-rest-framework"

  spec.files = [
    "README.md",
    "LICENSE",
    "VERSION",
    *Dir["app/**/*"],
    *Dir["lib/**/*.rb"],
    *Dir["vendor/assets/**/*"],
  ]
end
