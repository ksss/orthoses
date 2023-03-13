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
      next true if (f == __FILE__)
      next true if f.match?(%r{\A(?:bin|known_sig)/}) # dir
      next true if f.match?(%r{\A\.(?:git)}) # git
      next true if f.match?(%r{\A(?:rbs_collection|Steepfile|Rakefile)}) # top file
      next true if f.match?(%r{_test\.rb\z}) # test
      false
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rbs", "~> 3.0"
end
