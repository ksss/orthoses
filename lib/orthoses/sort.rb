# frozen_string_literal: true

module Orthoses
  # use Orthoses::Sort
  class Sort
    def initialize(loader)
      @loader = loader
    end

    def call
      @loader.call.tap do |store|
        store.each do |name, content|
          content.sort!
        end
      end
    end
  end
end
