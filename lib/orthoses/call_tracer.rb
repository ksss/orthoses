# frozen_string_literal: true

module Orthoses
  # Trace :call event by TracePoint and capture arguments.
  #   def call
  #     scope = CallTracer.new
  #     scope.trace(ActiveRecord::Base.method(:scope)) do
  #       @loader.call
  #     end
  #     scope.results.each do |result|
  #       result.argument[:name]
  #       result.argument[:body]
  #       result.argument[:block]
  #     end
  class CallTracer
    class Result < Struct.new(:method, :argument, keyword_init: true)
    end

    attr_accessor :results

    def initialize
      @results = []
    end

    def trace(target, &block)
      t = TracePoint.new(:call) do |tp|
        called_method = tp.self.method(tp.method_id)
        argument = tp.parameters.each_with_object({}) do |op_name, hash|
          name = op_name[1]
          case name
          when :*, :**, :&, nil
            # skip
          else
            hash[name] = tp.binding.local_variable_get(name).then do |var|
              case var
              when Module
                var # avoid missing name
              else
                var.dup
              end
            rescue => err
              case var
              when Thread::Backtrace::Location
                # known
              else
                warn("#dup fail (#{err.class}) #{err.message}")
              end
              var
            end
          end
        end

        @results << Result.new(
          method: called_method,
          argument: argument,
        )
      end
      t.enable(target: target, &block)
    end
  end
end
