module Orthoses
  # Collect argument and return types during code running
  #     use Orthoses::Trace,
  #         patterns: ['Foo::Bar*']
  class Trace
    autoload :Attribute, 'orthoses/trace/attribute'
    autoload :Method, 'orthoses/trace/method'
    autoload :Targetable, 'orthoses/trace/targetable'

    def initialize(loader, patterns:)
      @loader = loader
      @patterns = patterns
    end

    def call
      @loader = Trace::Attribute.new(@loader, patterns: @patterns)
      @loader = Trace::Method.new(@loader, patterns: @patterns)
      @loader.call
    end
  end
end
