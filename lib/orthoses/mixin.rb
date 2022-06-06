# frozen_string_literal: true

module Orthoses
  class Mixin
    module Hook
      def include(*modules)
        super
      end
      def extend(*modules)
        super
      end
      def prepend(*modules)
        super
      end
    end

    def initialize(loader, if: nil)
      @loader = loader
      @if = binding.local_variable_get(:if)
    end

    def call
      ::Module.prepend(Hook)

      include = CallTracer.new
      extend = CallTracer.new
      prepend = CallTracer.new

      store = include.trace(::Module.method(:include)) do
        extend.trace(::Module.method(:extend)) do
          prepend.trace(::Module.method(:prepend)) do
            @loader.call
          end
        end
      end

      collect_definitions(store, include, :include)
      collect_definitions(store, extend, :extend)
      collect_definitions(store, prepend, :prepend)

      store
    end

    private

    def collect_definitions(store, call_tracer, how)
      call_tracer.results.each do |result|
        base_mod = result.method.receiver
        next unless base_mod.kind_of?(Module)

        base_mod_name = Utils.module_name(base_mod)
        next unless base_mod_name

        content = store[base_mod_name]
        result.argument[:modules].each do |mod|
          mod_name = Utils.module_name(mod)
          next unless mod_name

          known_type_params = Utils.known_type_params(mod)
          next unless known_type_params.nil? || known_type_params.empty?

          next unless @if.nil? || @if.call(base_mod, how, mod)

          store[mod_name]
          content << "#{how} #{mod_name}"
        end
      end
    end
  end
end
