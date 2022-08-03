# frozen_string_literal: true

module Orthoses
  # Trace :call event by TracePoint and capture arguments.
  #   def call
  #     scope = CallTracer.new
  #     scope.trace(ActiveRecord::Base.method(:scope)) do
  #       @loader.call
  #     end
  #     scope.captures.each do |capture|
  #       capture.argument[:name]
  #       capture.argument[:body]
  #       capture.argument[:block]
  #     end
  class CallTracer
    class Capture < Struct.new(:method, :argument, keyword_init: true)
    end

    autoload :Lazy, 'orthoses/call_tracer/lazy'
    require_relative 'call_tracer/capturable'

    include Capturable

    attr_accessor :captures

    def initialize
      @captures = []
      @target_tp = TracePoint.new(:call) do |tp|
        @captures << build_capture(tp)
      end
    end

    def trace(target, &block)
      @target_tp.enable(target: target, &block)
    end
  end
end
