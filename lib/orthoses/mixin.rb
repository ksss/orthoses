# frozen_string_literal: true

module Orthoses
  class Mixin
    CALL_GRAPH = {}

    module Hook
      def include(*modules)
        modules.each do |m|
          (CALL_GRAPH[self]||=[]) << [:include, m]
        end
        super
      end
      def extend(*modules)
        modules.each do |m|
          (CALL_GRAPH[self]||=[]) << [:extend, m]
        end
        super
      end
      def prepend(*modules)
        modules.each do |m|
          (CALL_GRAPH[self]||=[]) << [:prepend, m]
        end
        super
      end
    end

    def initialize(loader, if: nil)
      CALL_GRAPH.clear
      @loader = loader
      @if = binding.local_variable_get(:if)
    end

    def call
      ::Module.prepend(Hook)

      store = @loader.call

      CALL_GRAPH.dup.each do |base_mod, mixins|
        base_mod_name = Utils.module_name(base_mod) or next
        content = store[base_mod_name]
        mixins.each do |(how, mod)|
          mod_name = Utils.module_name(mod) or next
          next if mod_name.start_with?("Orthoses")
          next unless @if.nil? || @if.call(base_mod, how, mod)

          store[mod_name].header = "module #{mod_name}"
          content << "#{how} #{mod_name}#{type_params_sig(mod)}"
        end
      end

      store
    end

    private

    def type_params_sig(mod)
      if type_params = Utils.known_type_params(mod)
        if !type_params.empty?
          return "[#{type_params.map{"untyped"}.join(", ")}]"
        end
      end

      ""
    end
  end
end
