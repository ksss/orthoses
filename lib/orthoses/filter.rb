# frozen_string_literal: true

module Orthoses
  # Filter current store.
  # filter stored key and value if proc return true
  #   use Orthoses::Filter do |name, content|
  #     Orthoses.rbs_defined_class?(name)
  #   end
  class Filter
    def initialize(loader, if: nil, &block)
      @loader = loader
      @if = binding.local_variable_get(:if)
      @block = block || @if || raise(ArgumentError, "should give a block")
    end

    def call
      @loader.call.tap do |store|
        store.filter! do |name, content|
          @block.call(name, content).tap do
            Orthoses.logger.debug("Filter pass [#{name}]")
          end
        end
      end
    end
  end
end
