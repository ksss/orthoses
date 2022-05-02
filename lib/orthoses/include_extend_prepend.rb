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
            old_buffer = store.delete(mod)
            store[mod].tap do |buffer|
              if buffer.decl.nil?
                buffer.decl = RBS::AST::Declarations::Module.new(
                  name: Util.module_to_type_name(mod) || raise,
                  type_params: [],
                  self_types: [
                    RBS::AST::Declarations::Module::Self.new(
                      name: TypeName("BasicObject").absolute!,
                      args: [],
                      location: nil
                    )
                  ],
                  members: [],
                  annotations: [],
                  location: nil,
                  comment: nil
                )
              end
              buffer.lines.concat(old_buffer.lines)
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
