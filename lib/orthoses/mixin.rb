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

      store = include.trace(Hook.instance_method(:include)) do
        extend.trace(Hook.instance_method(:extend)) do
          prepend.trace(Hook.instance_method(:prepend)) do
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
      call_tracer.captures.each do |capture|
        base_mod = capture.method.receiver
        next unless base_mod.kind_of?(Module)

        base_mod_name = Utils.module_name(base_mod)
        next unless base_mod_name
        next if base_mod_name.include?("#")

        content = store[base_mod_name]
        capture.argument[:modules].each do |mod|
          mod_name = Utils.module_name(mod)
          next unless mod_name

          next if mod_name.start_with?("Orthoses")

          type_params_sig = ""
          if type_params = Utils.known_type_params(mod)
            if !type_params.empty?
              type_params_sig = "[#{type_params.map{"untyped"}.join(", ")}]"
            end 
          end

          next unless @if.nil? || @if.call(base_mod, how, mod)

          store[mod_name].header = "module #{mod_name}"
          content << "#{how} #{mod_name}#{type_params_sig}"
        end
      end
    end
  end
end
