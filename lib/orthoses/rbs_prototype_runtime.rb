module Orthoses
  # Call `rbs prototype runtime` and add to store
  #     use Orthoses::RBSPrototypeRuntime,
  #       patterns: ['Foo::*']
  class RBSPrototypeRuntime
    def initialize(
      loader,
      patterns: nil,
      method_definition_filter: nil,
      alias_filter: nil,
      constant_filter: nil,
      mixin_filter: nil,
      attribute_filter: nil
    )
      @loader = loader
      @patterns = patterns
      @method_definition_filter = method_definition_filter
      @alias_filter = alias_filter
      @constant_filter = constant_filter
      @mixin_filter = mixin_filter
      @attribute_filter = attribute_filter
    end

    def call
      @loader.call.tap do |store|
        content_env = Orthoses::Content::Environment.new(
          method_definition_filter: @method_definition_filter,
          alias_filter: @alias_filter,
          constant_filter: @constant_filter,
          mixin_filter: @mixin_filter,
          attribute_filter: @attribute_filter,
        )

        patterns = @patterns || store.keys
        env = RBS::Environment.new
        merge = false
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
