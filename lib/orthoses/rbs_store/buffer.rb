# frozen_string_literal: true

module Orthoses
  class RBSStore
    class Buffer
      attr_reader :env
      attr_reader :type_name
      attr_reader :lines
      attr_accessor :decl

      def initialize(env:, type_name:, lines: [], decl: nil)
        @env = env
        @type_name = type_name
        @lines = lines
        @decl = decl
      end

      def <<(line)
        @lines << line
      end

      def concat(other)
        @lines.concat(other)
      end

      def resolve!
        if decl.nil?
          auto_set_decl
        end
        body = @lines.join("\n")
        @lines.clear
        buffer = RBS::Buffer.new(name: "orthoses/rbs_store/buffer.rb", content: "#{key_name}\n#{body}\nend\n")
        RBS::Parser.parse_signature(buffer).each do |parsed_decl|
          before_members = parsed_decl.members.dup
          parsed_decl.members.uniq! { |m| [m.class, m.respond_to?(:name) ? m.name : nil] }
          (before_members - parsed_decl.members).each do |droped_member|
            Orthoses.logger.debug("#{decl.name}::#{droped_member.name.to_s}: #{droped_member.inspect} was droped since duplication")
          end
          @env << parsed_decl
        end
      end

      private

      def auto_set_decl
        val = Object.const_get(type_name.to_s)
        case val
        when Class
          super_class = if val.superclass != Object && mod_name = Util.module_name(val.superclass)
            RBS::AST::Declarations::Class::Super.new(
              name: TypeName(mod_name).absolute!,
              args: [],
              location: nil
            )
          end
          self.decl = RBS::AST::Declarations::Class.new(
            name: type_name,
            type_params: [],
            super_class: super_class,
            members: [],
            annotations: [],
            location: nil,
            comment: nil
          )
        when Module
          self.decl = RBS::AST::Declarations::Module.new(
            name: type_name,
            type_params: [],
            self_types: [],
            members: [],
            annotations: [],
            location: nil,
            comment: nil
          )
        else
          raise "unsupported decl=#{decl.inspect}"
        end
      end

      # from RBS::Writer
      def key_name
        case decl
        when RBS::AST::Declarations::Class
          super_class = if super_class = decl.super_class
                          " < #{name_and_args(super_class.name, super_class.args)}"
                        end
          "class #{name_and_params(decl.name, decl.type_params)}#{super_class}"
        when RBS::AST::Declarations::Module
          self_type = unless decl.self_types.empty?
                        " : #{decl.self_types.join(", ")}"
                      end
          "module #{name_and_params(decl.name, decl.type_params)}#{self_type}"
        when RBS::AST::Declarations::Interface
          "interface #{name_and_params(decl.name, decl.type_params)}"
        else
          raise "unsupported decl=#{decl.inspect}"
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
