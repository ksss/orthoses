# frozen_string_literal: true

module Orthoses
  module Outputable
    class ResolveTypeNames
      def initialize(loader)
        @loader = loader
      end

      def call
        @loader.call.tap do |store|
          env = Utils.rbs_environment(cache: false)

          signatures = store.map do |name, content|
            buffer = RBS::Buffer.new(content: content.to_rbs, name: "orthoses-resolve_type_names-#{name.downcase}.rbs")
            decls = [content.to_decl]

            # Add as known types
            env.add_signature(buffer: buffer, directives: [], decls: decls)

            # Will resolve names
            [buffer, [[], decls]]
          end.to_h

          # Reduce resolving names
          env.signatures.replace(signatures)
          env = env.resolve_type_names

          store.each do |name, content|
            out = StringIO.new
            writer = RBS::Writer.new(out: out)
            type_name = RBS::TypeName.parse(content.name).absolute!
            entry, members = entry_and_members(env, type_name)
            content.header = content_header(entry)
            members.each do |member|
              writer.write_member(member)
            end
            content.body.replace(out.string.lines)
          end
        end
      end

      private

      def entry_and_members(env, type_name)
        if type_name.class?
          env.class_decls[type_name]&.then do |entry|
            [entry, entry.decls.flat_map { |decl| decl.decl.members }]
          end
        elsif type_name.interface?
          env.interface_decls[type_name]&.then do |entry|
            [entry, [entry.decl.members]]
          end
        end.then do |entry, members|
          unless entry
            Orthoses.logger.warn "No entry for #{type_name}"
            return
          end
          [entry, members]
        end
      end

      def content_header(entry)
        case entry
        when RBS::Environment::ClassEntry
          class_header(entry.primary.decl)
        when RBS::Environment::ModuleEntry
          module_header(entry.primary.decl)
        when RBS::Environment::InterfaceEntry
          interface_header(entry.decl)
        else
          raise "unexpected entry: #{entry}"
        end
      end

      def class_header(decl)
        super_class = if super_class = decl.super_class
          " < #{name_and_args(super_class.name, super_class.args)}"
        end
        "class #{name_and_params(decl.name, decl.type_params)}#{super_class}"
      end

      def module_header(decl)
        self_type = unless decl.self_types.empty?
          " : #{decl.self_types.join(", ")}"
        end
        "module #{name_and_params(decl.name, decl.type_params)}#{self_type}"
      end

      def interface_header(decl)
        "interface #{name_and_params(decl.name, decl.type_params)}"
      end

      module WriterCopy
        def name_and_args(name, args)
          if name && args
            if args.empty?
              "#{name}"
            else
              "#{name}[#{args.join(", ")}]"
            end
          end
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
      end
      include WriterCopy
    end
  end
end
