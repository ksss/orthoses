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
          if mod.kind_of?(Module) && Util.module_name(mod) && Util.module_name(self)
            modules[Util.module_name(mod)] << [:include, Util.module_name(self)]
          end
        end

        define_method(:extended) do |mod|
          if mod.kind_of?(Module) && Util.module_name(mod) && Util.module_name(self)
            modules[Util.module_name(mod)] << [:extend, Util.module_name(self)]
          end
        end

        define_method(:prepended) do |mod|
          if mod.kind_of?(Module) && Util.module_name(mod) && Util.module_name(self)
            modules[Util.module_name(mod)] << [:prepend, Util.module_name(self)]
          end
        end
      end

      store = @loader.call(env)

      modules.each do |base_name, how_mods|
        lines = how_mods.filter_map do |how, mod|
          next unless Util.check_const_getable(mod) { |e| env[:logger]&.info(e) }
          next unless @if.nil? || @if.call(base_name, how, mod)

          if base_name == "Object"
            # avoid RecursiveAncestorError
            if bodies = store.delete(mod)
              store["module #{mod} : BasicObject"].concat(bodies)
            else
              store["module #{mod} : BasicObject"] = []
            end
          else
            store[mod] ||= []
          end

          "#{how} #{mod}"
        end
        store[base_name].concat(lines)
      end

      store
    end
  end
end
