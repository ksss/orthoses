# frozen_string_literal: true

module Orthoses
  # use Orthoses::Tap do |store|
  #   store["Foo::Bar"] << "def baz: () -> void"
  # end
  class Tap
    def initialize(loader, &block)
      @loader = loader
      @block = block
    end

    def call
      @loader.call.tap do |store|
        @block.call(store)
      end
    end
  end
end
