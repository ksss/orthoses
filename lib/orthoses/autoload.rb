# frozen_string_literal: true

module Orthoses
  class Autoload
    module Hook
      def autoload(name, path)
        super
      end
    end

    def initialize(loader)
      @loader = loader
    end

    def call
      ::Module.prepend(Hook)

      autoload = CallTracer.new

      store = autoload.trace(Hook.instance_method(:autoload)) do
        @loader.call
      end

      autoload.captures.each do |capture|
        base_mod = capture.method.receiver
        name = capture.argument[:name]
        begin
          base_mod.const_get(name)
        rescue LoadError, ArgumentError => e
          Orthoses.logger.warn("[Orthoses::Autoload] raise `#{e.message} (#{e.class})` when try to unautoload `#{base_mod}::#{name}`")
        end
      end

      store
    end
  end
end
