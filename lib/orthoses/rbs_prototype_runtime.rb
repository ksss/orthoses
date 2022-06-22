module Orthoses
  # Call `rbs prototype runtime` and add to store
  #     use Orthoses::RBSPrototypeRuntime,
  #       patterns: ['Foo::*']
  class RBSPrototypeRuntime
    def initialize(loader, patterns:)
      @loader = loader
      @patterns = patterns
    end

    def call
      @loader.call.tap do |store|
        content_env = Orthoses::Content::Environment.new

        patterns = @patterns
        env = RBS::Environment.new
        merge = true
        owners_included = []
        RBS::Prototype::Runtime.new(
          patterns: patterns,
          env: env,
          merge: merge,
          owners_included: owners_included,
        ).decls.each do |decl|
          content_env << decl
        end

        content_env.write_to(store: store)
      end
    end
  end
end
