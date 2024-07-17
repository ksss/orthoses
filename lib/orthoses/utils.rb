# frozen_string_literal: true

module Orthoses
  module Utils
    autoload :TypeList, "orthoses/utils/type_list"
    autoload :Underscore, "orthoses/utils/underscore"

    def self.unautoload!
      warn "`Orthoses::Utils.unautoload!` is deprecated. please use `Orthoses::Autoload` middleware instead."
      ObjectSpace.each_object(Module) do |mod|
        each_const_recursive(mod)
      end
    end

    def self.each_const_recursive(root, cache: {}, on_error: nil, &block)
      root.constants(false).sort.each do |const|
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

    def self.rbs_defined_const?(name, library: nil, collection: true)
      return false if name.start_with?("#<")
      env = rbs_environment(library: library, collection: collection)
      name = name.sub(/Object::/, '')
      target = rbs_type_name(name)
      env.constant_decls.has_key?(target)
    end

    def self.rbs_defined_class?(name, library: nil, collection: true)
      return false if name.start_with?("#<")
      env = rbs_environment(library: library, collection: collection)
      target = rbs_type_name(name)
      env.class_decls.has_key?(target)
    end

    def self.rbs_type_name(name)
      name = "::#{name}" if !name.start_with?("::")
      RBS::Namespace.parse(name).to_type_name
    end

    def self.rbs_environment(library: nil, collection: true, cache: true)
      @env_cache ||= {}
      if cache && hit = @env_cache[[library, collection]]
        return hit
      end

      loader = RBS::EnvironmentLoader.new

      if collection
        config_path = RBS::Collection::Config.find_config_path || RBS::Collection::Config::PATH || raise("needs rbs_collection.yaml")
        lock_path = RBS::Collection::Config.to_lockfile_path(config_path)
        raise "needs rbs_collection.yaml file" unless lock_path.file?
        lock = RBS::Collection::Config::Lockfile.from_lockfile(
          lockfile_path: lock_path,
          data: YAML.load_file(lock_path.to_s)
        )
        loader.add_collection(lock)
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

    def self.object_to_rbs(object, strict: false)
      case object
      when Class, Module
        if name = module_name(object)
          "singleton(#{name})"
        else
          "untyped"
        end
      when Integer, Symbol, String
        if strict
          object.inspect
        else
          module_name(object.class) || 'untyped'
        end
      when true, false
        if strict
          object.inspect
        else
          "bool"
        end
      when nil
        "nil"
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
            "Array[#{TypeList.new(ary).inject}]"
          end
        end
      when Hash
        if object.empty?
          "Hash[untyped, untyped]"
        else
          if strict && object.keys.all? { |key| key.is_a?(Symbol) && /\A\w+\z/.match?(key) }
            "{ #{object.map { |k, v| "#{k}: #{object_to_rbs(v, strict: strict)}" }.join(', ')} }"
          else
            keys = object.keys.map { |k| object_to_rbs(k, strict: strict) }
            values = object.values.map { |v| object_to_rbs(v, strict: strict) }
            "Hash[#{TypeList.new(keys).inject}, #{TypeList.new(values).inject}]"
          end
        end
      when Range
        type = object_to_rbs(object.begin || object.end, strict: false)
        "Range[#{type}]"
      when ARGF
        # see also https://github.com/ruby/rbs/pull/975
        'untyped'
      else
        module_name(object.class) || 'untyped'
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

    def self.attached_module_name(mod)
      if mod.respond_to?(:attached_object)
        attached_object = mod.attached_object
        (attached_object&.is_a?(Module) && attached_object.name) || nil
      else
        # e.g. `Minitest::Spec::DSL#to_s` may return `nil` with `#to_s`
        m = mod.to_s&.match(/#<Class:([\w:]+)>/)
        m && m[1]
      end
    end

    def self.known_type_params(name)
      type_name =
        case name
        when String
          TypeName(name).absolute!
        when Module
          module_to_type_name(name).absolute!
        when RBS::TypeName
          name.absolute!
        else
          raise TypeError, "#{name.class} is not supported yet"
        end
      rbs_environment.class_decls[type_name]&.then do |entry|
        entry.type_params
      end
    end

    def self.new_store
      Hash.new { |h, k| h[k] = Content.new(name: k) }
    end
  end
end
