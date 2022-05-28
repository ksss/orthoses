# frozen_string_literal: true

module Orthoses
  module Utils
    def self.unautoload!
      ObjectSpace.each_object(Module) do |mod|
        each_const_recursive(mod)
      end
    end

    def self.each_const_recursive(root, cache: {}, on_error: nil, &block)
      root.constants(false).each do |const|
        val = root.const_get(const)
        next if cache[const].equal?(val)
        cache[const] = val
        next if val.equal?(root)
        block.call(root, const, val) if block
        if val.respond_to?(:constants)
          each_const_recursive(val, cache: cache, on_error: on_error, &block)
        end
      rescue LoadError, StandardError => err
        Orthoses.logger.warn("Orthoses::Utils.each_const_recursive: #{err.class}: #{err.message} on #{err.backtrace.first}")
        if on_error
          on_error.call(ConstLoadError.new(root: root, const: const, error: err))
        end
      end
    end

    def self.rbs_defined_const?(name, library: nil, collection: false)
      return false if name.start_with?("#<")
      env = rbs_environment(library: library, collection: collection)
      name = name.sub(/Object::/, '')
      target = rbs_type_name(name)
      env.constant_decls.has_key?(target)
    end

    def self.rbs_defined_class?(name, library: nil, collection: false)
      return false if name.start_with?("#<")
      env = rbs_environment(library: library, collection: collection)
      target = rbs_type_name(name)
      env.class_decls.has_key?(target)
    end

    def self.rbs_type_name(name)
      name = "::#{name}" if !name.start_with?("::")
      RBS::Namespace.parse(name).to_type_name
    end

    def self.rbs_environment(library: nil, collection: false, cache: true)
      @env_cache ||= {}
      if cache && hit = @env_cache[[library, collection]]
        return hit
      end

      loader = RBS::EnvironmentLoader.new

      if collection
        lock = RBS::Collection::Config::PATH&.then { |p| RBS::Collection::Config.lockfile_of(p) }
        loader.add_collection(lock) if lock
      end

      case library
      when "stdlib"
        RBS::Repository::DEFAULT_STDLIB_ROOT.each_entry do |path|
          lib = path.to_s
          loader.add(library: lib.to_s, version: nil) unless lib == "." || lib == ".."
        end
      else
        Array(library).each do |lib|
          loader.add(library: lib.to_s, version: nil)
        end
      end

      RBS::Environment.from_loader(loader).resolve_type_names.tap do |env|
        @env_cache[[library, collection]] = env if cache
      end
    end

    def self.object_to_rbs(object, strict:)
      case object
      when Class, Module
        "singleton(#{object})"
      when Integer, Symbol, String
        if strict
          object.inspect
        else
          Utils.module_name(object.class) || 'untyped'
        end
      when true, false, nil
        object.inspect
      when Set
        if object.empty?
          "Set[untyped]"
        else
          ary = object.map do |o|
            object_to_rbs(o, strict: strict)
          end
          "Set[#{ary.uniq.join(' | ')}]"
        end
      when Array
        if object.empty?
          "Array[untyped]"
        else
          ary = object.map do |o|
            object_to_rbs(o, strict: strict)
          end
          if strict
            "[#{ary.join(', ')}]"
          else
            "Array[#{ary.uniq.join(' | ')}]"
          end
        end
      when Hash
        if object.empty?
          "Hash[untyped, untyped]"
        else
          if strict && object.keys.all? { |key| key.is_a?(Symbol) && /\A\w+\z/.match?(key) }
            "{ #{object.map { |k, v| "#{k}: #{object_to_rbs(v, strict: strict)}" }.join(', ')} }"
          else
            keys = object.keys.map { |k| object_to_rbs(k, strict: strict) }.uniq
            values = object.values.map { |v| object_to_rbs(v, strict: strict) }.uniq
            "Hash[#{keys.join(' | ')}, #{values.join(' | ')}]"
          end
        end
      when ARGF
        # see also https://github.com/ruby/rbs/pull/975
        'untyped'
      else
        Utils.module_name(object.class) || 'untyped'
      end
    end

    UNBOUND_NAME_METHOD = Module.instance_method(:name)

    # Want to get the module name even if the method is overwritten.
    # e.g.) Rails::Info
    def self.module_name(mod)
      return nil unless mod
      UNBOUND_NAME_METHOD.bind(mod).call
    end

    def self.module_to_type_name(mod)
      name = Utils.module_name(mod)
      if name && !name.empty?
        TypeName(name)
      else
        nil
      end
    end

    def self.known_type_params(name)
      type_name =
        case name
        when String
          TypeName(name).absolute!
        when Module
          module_to_type_name(name)
        else
          raise TypeError
        end
      rbs_environment(collection: true).class_decls[type_name]&.then do |entry|
        entry.decls.first.decl.type_params
      end
    end

    def self.new_store
      Hash.new { |h, k| h[k] = Content.new(name: k) }
    end
  end
end
