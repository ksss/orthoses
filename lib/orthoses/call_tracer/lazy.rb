# frozen_string_literal: true

module Orthoses
  class CallTracer
    class Lazy
      include Capturable

      attr_reader :captures

      def initialize
        @captures = []
        @lazy_trace_point = LazyTracePoint.new(:call) do |tp|
          @captures << build_capture(tp)
        end
      end

      def trace(name, &block)
        @lazy_trace_point.enable(target: name, &block)
      end
    end
  end
end
