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

    attr_accessor :captures

    def initialize
      @captures = []
    end

    METHOD_METHOD = Kernel.instance_method(:method)

    def trace(target, &block)
      t = TracePoint.new(:call) do |tp|
        called_method = METHOD_METHOD.bind(tp.self).call(tp.method_id)
        argument = tp.parameters.each_with_object({}) do |op_name, hash|
          name = op_name[1]
          case name
          when :*, :**, :&, nil
            # skip
          else
            hash[name] = tp.binding.local_variable_get(name).then do |var|
              case var
              when Module, Thread::Backtrace::Location
                var
              else
                var.dup
              end
            rescue => err
              warn("#dup fail (#{err.class}) #{err.message}")
              var
            end
          end
        end

        @captures << Capture.new(
          method: called_method,
          argument: argument,
        )
      end
      t.enable(target: target, &block)
    end
  end
end
