module Orthoses
  class Content
    class Environment
      def initialize(constant_filter: nil, mixin_filter: nil)
        @load_env = RBS::Environment.new
        @known_env = Utils.rbs_environment(collection: true)
        @constant_filter = constant_filter
        @mixin_filter = mixin_filter
      end

      def <<(decl)
        if known_class_entry = @known_env.class_decls[decl.name.absolute!]
          decl.type_params.replace(known_class_entry.primary.decl.type_params)
        end
        @load_env << decl
      rescue RBS::DuplicatedDeclarationError => err
        Orthoses.logger.warn(err.inspect)
      end

      def write_to(store:)
        each do |add_content|
          content = store[add_content.name]
          content.header ||= add_content.header
          content.concat(add_content.body)
        end
      end

      def each
        header_builder = HeaderBuilder.new(env: @load_env)

        @load_env.class_decls.each do |type_name, m_entry|
          name = type_name.relative!.to_s
          content = Content.new(name: name)
          content.header = header_builder.build(entry: m_entry, name_hint: name)
          decls_to_lines(m_entry.decls.map(&:decl)).each do |line|
            content << line
          end
          yield content
        end

        @load_env.interface_decls.each do |type_name, s_entry|
          name = type_name.relative!.to_s
          content = Content.new(name: name)
          content.header = header_builder.build(entry: s_entry)
          decls_to_lines([s_entry.decl]).each do |line|
            content << line
          end
          yield content
        end
      end

      def decls_to_lines(decls)
        out = StringIO.new
        writer = RBS::Writer.new(out: out)
        decls.each do |decl|
          next unless decl.respond_to?(:members)
          decl.members.each do |member|
            next if member.respond_to?(:members)
            case member
            when RBS::AST::Declarations::Constant
              next unless @constant_filter.nil? || @constant_filter.call(member)
            when RBS::AST::Members::Mixin
              next unless @mixin_filter.nil? || @mixin_filter.call(member)
            end
            writer.write_member(member)
          end
        end
        out.string.each_line(chomp: true).to_a
      end
    end
  end
end
