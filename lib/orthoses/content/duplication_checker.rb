module Orthoses
  class Content
    # Check and drop duplication method, const etc...
    class DuplicationChecker
      def initialize(decl)
        @decl = decl
        @uniq_map = {}
      end

      def <<(member)
        key = member_key(member)
        if @uniq_map.key?(key)
          Orthoses.logger.warn("#{@decl.name}::#{member_to_s(member)} was droped since duplication")
        else
          @uniq_map[key] = member
        end
      end

      def uniq_members
        @uniq_map.values
      end

      private

      def member_to_s(member)
        out = StringIO.new
        RBS::Writer.new(out: out).write_member(member)
        out.string.chomp
      end

      def member_key(member)
        case member
        when RBS::AST::Members::MethodDefinition
          # member.types.hash is different
          [member.class, member.name, member.kind]
        when RBS::AST::Members::Mixin
          # include Mod[Arg] => keep
          # include Mod      => drop
          [member.class, member.name]
        when RBS::AST::Members::Attribute
          # attr_reader foo: String => keep
          # attr_reader foo: void   => drop
          [member.class, member.name]
        when RBS::AST::Members::Var
          # @foo: Integer => keep
          # @foo: String  => drop
          [member.class, member.name]
        else
          member
        end
      end
    end
  end
end
