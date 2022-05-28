module Orthoses
  class Content
    class HeaderBuilder
      def initialize(env:)
        @env = env
        @resolver = RBS::TypeNameResolver.from_env(env)
      end

      def build(entry:, name_hint: nil)
        case entry
        when RBS::Environment::ModuleEntry
          build_module(entry: entry, name_hint: name_hint)
        when RBS::Environment::ClassEntry
          build_class(entry: entry, name_hint: name_hint)
        when RBS::Environment::SingleEntry
          build_interface(entry: entry, name_hint: name_hint)
        else
          raise
        end
      end

      private

      def build_module(entry:, name_hint: nil)
        primary = entry.primary
        full_name = name_hint || primary.decl.name.relative!

        self_types =
          if primary.decl.self_types.empty?
            nil
          else
            " : #{primary.decl.self_types.join(', ')}"
          end

        "module #{name_and_params(full_name, primary.decl.type_params)}#{self_types}"
      end

      def build_class(entry:, name_hint: nil)
        primary = entry.primary
        full_name = name_hint || primary.decl.name.relative!

        "class #{name_and_params(full_name, primary.decl.type_params)}#{build_super_class(primary)}"
      end

      def build_super_class(primary)
        return nil if primary.decl.super_class.then { |s| s.nil? || s.name.relative!.to_s.then { |n| n == "Object" || n == "Random::Base" } }

        context = primary.outer.length.times.map do |i|
          primary.outer[0, i + 1].map(&:name).inject(:+).to_namespace.absolute!
        end
        context.push(RBS::Namespace.root)

        super_class_name = @resolver.resolve(primary.decl.super_class.name, context: context) || primary.decl.super_class.name.absolute!
        if primary.decl.super_class.args.empty?
          if super_class_entry = @env.class_decls[super_class_name]
            super_primary = super_class_entry.primary
            " < #{name_and_args(super_class_name, super_primary.decl.type_params.map { :untyped })}"
          else
            " < #{name_and_args(super_class_name, [])}"
          end
        else
          " < #{name_and_args(super_class_name, primary.decl.super_class.args)}"
        end
      end

      def build_interface(entry:, name_hint: nil)
        full_name = name_hint || entry.decl.name.relative!
        "interface #{name_and_params(full_name, entry.decl.type_params)}"
      end

      def name_and_params(name, params)
        if params.empty?
          "#{name}"
        else
          ps = params.each.map do |param|
            param.to_s
          end

          "#{name}[#{ps.join(", ")}]"
        end
      end

      def name_and_args(name, args)
        if name && args
          if args.empty?
            "#{name}"
          else
            "#{name}[#{args.join(", ")}]"
          end
        end
      end
    end
  end
end
