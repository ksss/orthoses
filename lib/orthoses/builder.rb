# frozen_string_literal: true

module Orthoses
  # Middleware builder like the Rack
  #   Builder.new do
  #     use Orthoses::Logger
  #     use Orthoses::PP
  #     run ->(_) { }
  #   end
  class Builder
    def initialize(&block)
      @use = []
      @run = nil
      instance_eval(&block) if block
    end

    def use(middleware, *args, **key, &block)
      @use << proc { |loader| middleware.new(loader, *args, **key, &block) }
    end

    def run(loader)
      @run = loader
    end

    def to_loader
      [*@use, Store.new(@run)].reverse.inject { |current, next_proc| next_proc[current] }
    end

    def call(env)
      to_loader.call(env)
    end
  end
end
