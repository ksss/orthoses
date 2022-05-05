# frozen_string_literal: true

module Orthoses
  # Filter current store.
  #   use Orthoses::Filter,
  #     # filter stored key and value if proc return true
  #     if: -> (name, content) { Orthoses.rbs_defined_class?(name) }
  class Filter
    def initialize(loader, if:)
      @loader = loader
      @if = binding.local_variable_get(:if)
    end

    def call
      @loader.call.tap do |store|
        store.filter! do |name, content|
          @if.call(name, content).tap do
            Orthoses.logger.debug("Filter pass [#{name}]")
          end
        end
      end
    end
  end
end
