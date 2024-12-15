module Orthoses
  # Collect argument and return types during code running
  #     use Orthoses::Trace,
  #         patterns: ['Foo::Bar*']
  class Trace
    autoload :Attribute, 'orthoses/trace/attribute'
    autoload :Method, 'orthoses/trace/method'
    autoload :Targetable, 'orthoses/trace/targetable'

    def initialize(loader, patterns:, trace_point_filter: nil, sort_union_types: true)
      @loader = loader
      @patterns = patterns
      @trace_point_filter = trace_point_filter
      @sort_union_types = sort_union_types
    end

    def call
      @loader = Trace::Attribute.new(@loader, patterns: @patterns, trace_point_filter: @trace_point_filter, sort_union_types: @sort_union_types)
      @loader = Trace::Method.new(@loader, patterns: @patterns, trace_point_filter: @trace_point_filter, sort_union_types: @sort_union_types)
      @loader.call
    end
  end
end
