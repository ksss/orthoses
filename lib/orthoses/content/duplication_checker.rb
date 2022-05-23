module Orthoses
  class Content
    # Check and drop duplication method, const etc...
    class DuplicationChecker
      def initialize(decl)
        @decl = decl
      end

      def update_decl
        uniq_map = {}
        @decl.members.reverse_each do |member|
          key = member_key(member)
          if uniq_map.key?(key)
            Orthoses.logger.warn("#{@decl.name}::#{member_to_s(member)} was droped since duplication")
          else
            uniq_map[key] = member
          end
        end
        drop_known_method_definition(uniq_map)
        @decl.members.replace(uniq_map.values.reverse)
      end

      private

      def drop_known_method_definition(uniq_map)
        env = Utils.rbs_environment(collection: true)
        if m_entry = env.class_decls[@decl.name.absolute!]
          m_entry.decls.each do |d|
            d.decl.members.each do |member|
              case member
              when RBS::AST::Members::MethodDefinition, RBS::AST::Members::Alias
                uniq_map.delete(member_key(member))
              end
            end
          end
        end
      end

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
        when RBS::AST::Members::LocationOnly
          [member.class]
        when RBS::AST::Members::Alias
          [RBS::AST::Members::MethodDefinition, member.new_name, member.kind]
        else
          [member.class, member.name]
        end
      end
    end
  end
end
