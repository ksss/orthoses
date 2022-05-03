# frozen_string_literal: true

require "bundler/gem_tasks"
require "rgot/cli"

task :test do
  Rgot::Cli.new(%w[-v --require orthoses lib]).run
end

task default: :test

desc "generate self signature to `sig` dir"
task :generate_self_sig do
  Pathname('sig').rmtree rescue nil
  require_relative 'lib/orthoses'
  Orthoses::Builder.new do
    use Orthoses::CreateFileByName,
      base_dir: 'sig',
      header: "# THIS IS GENERATED CODE from `$ rake generate_self_sig`"
    use Orthoses::Filter,
      if: ->(name, _) {
        name.start_with?("Orthoses")
      }
    use Orthoses::IncludeExtendPrepend
    use Orthoses::Constant
    use Orthoses::KnownSig,
      dir: 'known_sig'
    use Orthoses::Walk,
      root: "Orthoses"
    run ->(_) { }
  end.call({})
end
