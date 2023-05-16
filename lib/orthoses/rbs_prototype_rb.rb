module Orthoses
  # Call `rbs prototype rb` and add to store
  #     use Orthoses::RBSPrototypeRB,
  #       paths: Dir.glob("lib/**/*.rb")
  class RBSPrototypeRB
    def initialize(loader, paths:, method_definition_filter: nil, constant_filter: nil, mixin_filter: nil, attribute_filter: nil)
      @loader = loader
      @paths = paths
      @method_definition_filter = method_definition_filter
      @constant_filter = constant_filter
      @mixin_filter = mixin_filter
      @attribute_filter = attribute_filter
    end

    def call
      @loader.call.tap do |store|
        parser = RBS::Prototype::RB.new
        @paths.each do |path|
          begin
            Orthoses.logger.debug("parse #{path} by RBS::Prototype::RB")
            parser.parse File.read(path.to_s)
          rescue => err
            Orthoses.logger.error("Parse error #{err.inspect} by RBS::Prototype::RB #{path}")
          end
        end
        env = Orthoses::Content::Environment.new(
          method_definition_filter: @method_definition_filter,
          constant_filter: @constant_filter,
          mixin_filter: @mixin_filter,
          attribute_filter: @attribute_filter,
        )
        parser.decls.each do |decl|
          env << decl
        end
        env.write_to(store: store)
      end
    end
  end
end
