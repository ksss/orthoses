# frozen_string_literal: true

module Orthoses
  # use Orthoses::ResolveTypeNames
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
          type_name = TypeName(content.name).absolute!
          entry = env.class_decls[type_name] || raise
          content.header = content_header(entry)
          entry.decls.each do |decl|
            decl.decl.members.each do |member|
              writer.write_member(member)
            end
          end
          content.body.replace(out.string.lines)
        end
      end
    end

    private

    def content_header(entry)
      case primary_decl = entry.primary.decl
      when RBS::AST::Declarations::Class
        class_header(primary_decl)
      when RBS::AST::Declarations::Module
        module_header(primary_decl)
      else
        raise "unexpected decl: #{primary_decl.class}"
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
