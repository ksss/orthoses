# frozen_string_literal: true

module Orthoses
  class Trace
    module Targetable
      def target?(name)
        return false if @trace_point_filter && !@trace_point_filter.call(name)

        @patterns.any? do |pattern|
          if pattern.end_with?("*")
            (name || "").start_with?(pattern.chop)
          else
            name == pattern
          end
        end
      end
    end
  end
end
