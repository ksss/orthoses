# frozen_string_literal: true

module Orthoses
  class CallTracer
    class Lazy < LazyTracePoint
      include Capturable

      attr_reader :captures

      def initialize
        @captures = []
        super(:call) do |tp|
          @captures << build_capture(tp)
        end
      end

      def trace(name, &block)
        enable(target: name, &block)
      end
    end
  end
end
