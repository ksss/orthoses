# frozen_string_literal: true

module Orthoses
  # Internal middleware for return RBSStore object
  # Builder set this middleware on last stack by default
  class Store
    def initialize(loader)
      @loader = loader
    end

    def call(env)
      @loader.call(env)
      RBSStore.new
    end
  end
end
