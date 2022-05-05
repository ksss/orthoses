# frozen_string_literal: true

module Orthoses
  # Middleware builder like the Rack
  #   Builder.new do
  #     use Orthoses::CreateFileByName
  #     use Orthoses::Constant
  #     use Orthoses::IncludeExtendPrepend
  #     use Orthoses::Walk,
  #       root: "Foo"
  #     run ->(_) { require 'foo' }
  #   end
  class Builder
    def initialize(&block)
      @use = []
      @run = nil
      instance_eval(&block) if block
    end

    module CallLogable
      def call(env)
        Orthoses.logger.info("[#{self.class}]#call start")
        super.tap do
          Orthoses.logger.info("[#{self.class}]#call end")
        end
      end
    end

    def use(middleware, *args, **key, &block)
      @use << proc do |loader|
        middleware.new(loader, *args, **key, &block).tap do |m|
          m.extend CallLogable
        end
      end
    end

    def run(loader)
      use Store
      @run = proc do |env|
        Orthoses.logger.info("[loader].call start")
        loader.call(env).tap do
          Orthoses.logger.info("[loader].call end")
        end
      end
    end

    def to_loader
      @use.reverse.inject(@run) { |current, next_proc| next_proc[current] }
    end

    def call(env)
      to_loader.call(env)
    end
  end
end
