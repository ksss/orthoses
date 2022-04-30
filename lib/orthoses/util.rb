module Orthoses
  module Util
    VIRTUAL_NAMESPACE = /\A(?<kind>module|class|interface)\s+(?<name>[\w:]+)(?<others>.+)?/

    def self.unautoload!
      ObjectSpace.each_object(Module) do |mod|
        each_const_recursive(mod)
      end
    end

    def self.each_const_recursive(root, cache: {}, on_error: nil, &block)
      root.constants(false).each do |const|
        val = root.const_get(const)
        next if cache[val]
        cache[val] = true
        next if val.equal?(root)
        block.call(root, const, val) if block
        if val.respond_to?(:constants)
          each_const_recursive(val, cache: cache, on_error: on_error, &block)
        end
      rescue LoadError, StandardError => err
        if on_error
          on_error.call(ConstLoadError.new(root: root, const: const, error: err))
        end
      end
    end

    def self.rbs_defined_const?(name, library: nil, collection: false)
      return false if name.start_with?("#<")
      env = rbs_environment(library: library, collection: collection)
      name.sub!(/Object::/, '')
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

    def self.rbs_environment(library: nil, collection: false)
      @env_cache ||= {}
      if hit = @env_cache[[library, collection]]
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
          loader.add(library: lib.to_s) unless lib == "." || lib == ".."
        end
      else
        Array(library).each do |lib|
          loader.add(library: lib.to_s)
        end
      end

      environment = RBS::Environment.from_loader(loader).resolve_type_names
      @env_cache[[library, collection]] = environment
    end

    def self.string_to_namespaces(full_name)
      match = VIRTUAL_NAMESPACE.match(full_name)
      if match
        full_name = match[:name] or raise
      end
      name_splited = full_name.split('::')

      name_splited.map.with_index do |part, index|
        if match && name_splited.length == index + 1
          next "#{match[:kind]} #{part}#{match[:others]}"
        end

        begin
          const = name_splited[0, index + 1].join('::')
          val = Object.const_get(const)
        rescue NameError => error
          if match
            # use virtual module
            next "module #{part}"
          end
          raise ConstLoadError.new(root: name_splited.first, const: const, error: error)
        end

        type_params = known_type_params(const)&.then do |type_params|
          if type_params.empty?
            nil
          else
            "[#{type_params.join(', ')}]"
          end
        end

        case val
        when Class
          if val.superclass == Module
            "module #{part}#{type_params}"
          elsif val.superclass.nil? ||
              val.superclass == Object ||
              val.superclass.singleton_class? ||
              val.superclass.name.nil? ||
              val.equal?(Random) # https://github.com/ruby/rbs/pull/977
            "class #{part}#{type_params}"
          else
            "class #{part}#{type_params} < ::#{val.superclass}"
          end
        when Module
          "module #{part}#{type_params}"
        else
          raise NameSpaceError, "#{val.inspect} must be a class/module"
        end
      end
    end

    def self.object_to_rbs(object)
      case object
      when Class, Module
        "singleton(#{object})"
      when Integer, Symbol, String, true, false, nil
        object.inspect
      when Set
        if object.empty?
          "Set[untyped]"
        else
          ary = object.map do |o|
            object_to_rbs(o)
          end
          "Set[#{ary.uniq.join(' | ')}]"
        end
      when Array
        if object.empty?
          "Array[untyped]"
        else
          ary = object.map do |o|
            object_to_rbs(o)
          end
          "[#{ary.join(', ')}]"
        end
      when Hash
        if object.empty?
          "Hash[untyped, untyped]"
        else
          if object.keys.all? { |key| key.is_a?(Symbol) && /\A[a-zA-Z0-9_]+\z/.match?(key) }
            "{ #{object.map { |k, v| "#{k}: #{object_to_rbs(v)}" }.join(', ')} }"
          else
            keys = object.keys.map { |k| object_to_rbs(k) }.uniq
            values = object.values.map { |k| object_to_rbs(k) }.uniq
            "Hash[#{keys.join(' | ')}, #{values.join(' | ')}]"
          end
        end
      else
        Util.module_name(object.class) || 'untyped'
      end
    end

    def self.check_const_getable(name, &block)
      begin
        mod = Object.const_get(name)
      rescue NameError => name_error
        if ["wrong constant name", "uninitialized constant"].any? { |msg| name_error.message.include?(msg) }
          block.call(name_error) if block
          return false
        else
          raise
        end
      rescue LoadError => load_error
        if ["cannot load such file"].any? { |msg| load_error.message.include?(msg) }
          block.call(load_error) if block
          return false
        else
          raise
        end
      rescue => error
        block.call(error) if block
        return false
      end

      return false if mod.singleton_class?
      return false if mod.name.nil?

      true
    end

    UNBOUND_NAME_METHOD = Module.instance_method(:name)

    # Want to get the module name even if the method is overwritten.
    # e.g.) Rails::Info
    def self.module_name(mod)
      UNBOUND_NAME_METHOD.bind(mod).call
    end

    def self.known_type_params(name)
      rbs_environment(library: "stdlib", collection: true).class_decls[rbs_type_name(name)]&.then do |entry|
        entry.decls.first.decl.type_params
      end
    end
  end
end
