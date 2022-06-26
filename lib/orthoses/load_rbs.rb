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
        paths = @paths
        paths = paths.call if paths.instance_of?(Proc)
        env = Content::Environment.load_from_paths(paths.to_a)
        env.write_to(store: store)
      end
    end
  end
end
