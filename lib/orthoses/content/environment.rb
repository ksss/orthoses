module Orthoses
  class Content
    class Environment
      def initialize(constant_filter: nil, mixin_filter: nil)
        @env = RBS::Environment.new
        @constant_filter = constant_filter
        @mixin_filter = mixin_filter
      end

      def <<(decl)
        @env << decl
      end

      def write_to(store:)
        each do |add_content|
          content = store[add_content.name]
          # content.header = add_content.header
          content.concat(add_content.body)
        end
      end

      def each
        each_class do |content|
          yield content
        end
        each_interface do |content|
          yield content
        end
      end

      def each_class
        @env.class_decls.each do |type_name, m_entry|
          name = type_name.relative!.to_s
          content = Content.new(name: name)
          case decl = m_entry.decls.first.decl
          when RBS::AST::Declarations::Module
            self_types = decl.self_types.empty? ? nil : " : #{decl.self_types.join(', ')}"
            content.header = "module #{name_and_params(name, decl.type_params)}#{self_types}"
          when RBS::AST::Declarations::Class
            super_class = decl.super_class.nil? ? nil : " < #{name_and_args(decl.super_class.name, decl.super_class.args)}"
            content.header = "class #{name_and_params(name, decl.type_params)}#{super_class}"
          else
            raise
          end
          decls_to_lines(m_entry.decls.map(&:decl)).each do |line|
            content << line
          end
          yield content
        end
      end

      def each_interface
        @env.interface_decls.each do |type_name, s_entry|
          name = type_name.relative!.to_s
          content = Content.new(name: name)
          decl = s_entry.decl
          content.header = "interface #{name_and_params(name, decl.type_params)}"
          decls_to_lines([decl]).each do |line|
            content << line
          end
          yield content
        end
      end

      private

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
