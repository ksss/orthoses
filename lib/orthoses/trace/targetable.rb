# frozen_string_literal: true

module Orthoses
  class Trace
    module Targetable
      def target?(name, tp)
        if @patterns.respond_to?(:call)
          @patterns.call(name, tp)
        else
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
end
