# frozen_string_literal: true

require_relative "lib/orthoses/version"

Gem::Specification.new do |spec|
  spec.name = "orthoses"
  spec.version = Orthoses::VERSION
  spec.authors = ["ksss"]
  spec.email = ["co000ri@gmail.com"]

  spec.summary = "Framework for Generate RBS"
  spec.description = "Build RBS by Rack base architecture"
  spec.homepage = "https://github.com/ksss/orthoses"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    [
      %w[CODE_OF_CONDUCT.md LICENSE.txt README.md],
      Dir.glob("lib/**/*.rb").grep_v(/_test\.rb\z/),
      Dir.glob("sig/**/*.rbs")
    ].flatten
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rbs", "~> 3.0"
end
