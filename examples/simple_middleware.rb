module Orthoses
  class Simple
    def initialize(loader)
      @loader = loader
    end

    def call
      @loader.call
    end
  end
end
