# frozen_string_literal: true

require "bundler/gem_tasks"
require "rgot/cli"

task :test do
  require 'orthoses'
  Orthoses.logger.level = :error
  Rgot::Cli.new(%w[-v lib integration_test]).run
end

desc "generate self signature to `sig` dir"
task :generate_self_sig do
  Pathname('sig').rmtree rescue nil
  require_relative 'lib/orthoses'
  Orthoses.logger.level = :info
  Orthoses::Builder.new do
    use Orthoses::CreateFileByName,
      base_dir: 'sig',
      header: "# THIS IS GENERATED CODE from `$ rake generate_self_sig`"
    use Orthoses::Filter,
      if: ->(name, _) {
        name.start_with?("Orthoses")
      }
    use Orthoses::Mixin
    use Orthoses::Constant, strict: true
    use Orthoses::LoadRBS,
      paths: Dir.glob("known_sig/**/*.rbs")
    use Orthoses::RBSPrototypeRB,
      paths: Dir.glob("lib/**/*.rb").grep_v(/_test\.rb/),
      constant_filter: ->(_) { false },
      mixin_filter: ->(_) { false },
      attribute_filter: ->(_) { false }
    use Orthoses::Walk,
      root: "Orthoses"
    run ->() { }
  end.call
end

task :validate do
  sh "rbs -I sig validate --silent"
end

task default: [:generate_self_sig, :validate, :test]
