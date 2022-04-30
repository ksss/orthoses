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
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rbs", "~> 2.0"
  spec.add_dependency "pathname"
end
