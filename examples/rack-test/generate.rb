require 'pathname'
require 'orthoses'
require 'fileutils'

include FileUtils

out = Pathname('out')
out.rmtree rescue nil

Orthoses.logger.level = :warn
Orthoses::Builder.new do
  use Orthoses::CreateFileByName,
    base_dir: out.to_s
  # use Orthoses::Sort
  use Orthoses::Filter do |name, content|
    name.start_with?("Rack::Test")
  end
  use Orthoses::Trace,
    patterns: ['Rack::Test*']
  run ->(){
    cd "src" do
      load "spec/all.rb"
      Minitest.run
      # avoid to run on at_exit
      module ::Minitest
        def self.run args = []
          0
        end
      end
    end
  }
end.call
