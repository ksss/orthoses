# frozen_string_literal: true

module Orthoses
  class LoadRBS
    # use Orthoses::LoadRBS,
    #   paths: Dir.glob("known_sig/**/*.rbs")
    def initialize(loader, paths:)
      @loader = loader
      @paths = paths
    end

    def call
      @loader.call.tap do |store|
        env = Content::Environment.new
        @paths.each do |path|
          Orthoses.logger.debug("Load #{path}")
          buffer = RBS::Buffer.new(name: path.to_s, content: File.read(path.to_s, encoding: "UTF-8"))
          RBS::Parser.parse_signature(buffer).each do |decl|
            env << decl
          end
        end
        env.write_to(store: store)
      end
    end
  end
end
