# frozen_string_literal: true

module Orthoses
  class IncludeExtendPrepend
    def initialize(loader, if: nil)
      @loader = loader
      @if = binding.local_variable_get(:if)
    end

    def call(env)
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

      store = @loader.call(env)

      modules.each do |base_mod, how_mods|
        next unless base_mod.kind_of?(Module)
        next unless Util.module_name(base_mod)

        lines = how_mods.filter_map do |how, mod|
          next unless Util.module_name(mod)
          known_type_params = Util.known_type_params(mod)
          next unless known_type_params.nil? || known_type_params.empty?
          next unless @if.nil? || @if.call(base_mod, how, mod)

          if how == :include && base_mod == Object
            # avoid RecursiveAncestorError
            old_content = store.delete(mod)
            store[mod].tap do |content|
              if content.header.nil?
                content.header = "module #{Util.module_to_type_name(mod)} : ::BasicObject"
              end
              content.body.concat(old_content.body) if old_content
            end
          else
            store[mod]
          end

          "#{how} #{mod}"
        end
        store[base_mod].concat(lines)
      end

      store
    end
  end
end
