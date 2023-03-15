# frozen_string_literal: true

module Orthoses
  class CallTracer
    # CallTracer::Lazy is possible to perform a trace
    # equivalent to CallTracer before method is defined.
    #     scope = CallTracerLazy.new
    #     scope.trace("ActiveRecord::Base#scope") do
    #       require 'active_record/all'
    #       @loader.call
    #     end
    #     scope.captures.each do |capture|
    #       capture.argument[:name]
    #       capture.argument[:body]
    #       capture.argument[:block]
    #     end
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
