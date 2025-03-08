# frozen_string_literal: true

require "bundler/gem_tasks"
require "rgot/cli"

require "rake/testtask"
Rake::TestTask.new do |task|
  task.libs = %w[lib test]
  task.test_files = FileList["lib/**/*_test.rb"]
end

desc "generate self signature to `sig` dir"
task :sig do
  Pathname('sig').rmtree rescue nil
  require_relative 'lib/orthoses'
  Orthoses.logger.level = :info
  Orthoses::Builder.new do
    use Orthoses::CreateFileByName,
      depth: 2,
      to: 'sig',
      header: "# THIS IS GENERATED CODE from `$ rake sig`"
    use Orthoses::Filter do |name, _|
      name.start_with?("Orthoses")
    end
    use Orthoses::LoadRBS,
      paths: Dir.glob("known_sig/**/*.rbs")
    use Orthoses::Mixin
    use Orthoses::Constant
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

task default: [:sig, :validate, :test]
