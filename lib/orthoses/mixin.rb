# frozen_string_literal: true

module Orthoses
  class Mixin
    def initialize(loader, if: nil)
      @loader = loader
      @if = binding.local_variable_get(:if)
    end

    def call
      modules = Hash.new { |h, k| h[k] = [] }
      ::Module.module_eval do
        define_method(:included) do |mod|
          modules[mod] << [:include, self]
        end

        define_method(:extended) do |mod|
          modules[mod] << [:extend, self]
        end

        define_method(:prepended) do |mod|
          modules[mod] << [:prepend, self]
        end
      end

      store = @loader.call

      modules.each do |base_mod, how_mods|
        next unless base_mod.kind_of?(Module)
        base_mod_name = Utils.module_name(base_mod)
        next unless base_mod_name

        lines = how_mods.filter.map do |how, mod|
          mod_name = Utils.module_name(mod)
          next unless mod_name
          known_type_params = Utils.known_type_params(mod)
          next unless known_type_params.nil? || known_type_params.empty?
          next unless @if.nil? || @if.call(base_mod, how, mod)

          store[mod_name]

          "#{how} #{mod_name}"
        end
        store[base_mod_name].concat(lines)
      end

      store
    end
  end
end
