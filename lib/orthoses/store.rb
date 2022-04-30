module Orthoses
  # key = Module or Class name (String)
  # value = code lines (Array)
  class Store
    def initialize(loader)
      @loader = loader
    end

    def call(env)
      @loader.call(env)
      Hash.new { |h, k| h[k] = [] }
    end
  end
end
