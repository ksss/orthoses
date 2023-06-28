# frozen_string_literal: true

module Orthoses
  # Middleware builder like the Rack
  #   Builder.new do
  #     use Orthoses::CreateFileByName
  #     use Orthoses::Constant
  #     use Orthoses::Mixin
  #     use Orthoses::Walk,
  #       root: "Foo"
  #     run ->() { require 'foo' }
  #   end
  class Builder
    def initialize(&block)
      @use = []
      @runner = nil
      instance_eval(&block) if block
    end

    module CallLogable
      def call()
        Orthoses.logger.info("[#{self.class}]#call start")
        super.tap do
          Orthoses.logger.info("[#{self.class}]#call end")
        end
      end
    end

    def use(middleware, *args, **key, &block)
      Orthoses.logger.debug("use #{middleware}")
      @use << proc do |loader|
        middleware.new(loader, *args, **key, &block).tap do |m|
          m.extend CallLogable
        end
      end
    end

    def run(loader)
      use Store
      reset_runner(loader)
    end

    def reset_runner(loader)
      @runner = proc do
        Orthoses.logger.info("[loader].call start")
        loader.call.tap do
          Orthoses.logger.info("[loader].call end")
        end
      end
    end

    def to_loader
      @use.reverse.inject(@runner) { |current, next_proc| next_proc[current] }
    end

    def call
      to_loader.call
    end
  end
end
