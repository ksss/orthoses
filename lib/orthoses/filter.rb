# frozen_string_literal: true

module Orthoses
  # Filter current store.
  #   use Orthoses::Filter,
  #     # filter stored key and value if proc return true
  #     if: -> (name, bodies) { Orthoses.rbs_defined_class?(name) }
  class Filter
    def initialize(loader, if:)
      @loader = loader
      @if = binding.local_variable_get(:if)
    end

    def call(env)
      @loader.call(env).tap do |store|
        store.filter! do |name, buffer|
          @if.call(name, buffer)
        end
      end
    end
  end
end
