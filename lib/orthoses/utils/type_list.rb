# frozen_string_literal: true

module Orthoses
  module Utils
    # internal
    class TypeList
      UNTYPED = ::RBS::Types::Bases::Any.new(location: nil)
      NIL_TYPE = ::RBS::Types::Bases::Nil.new(location: nil)
      TRUE_TYPE = ::RBS::Types::Literal.new(literal: true, location: nil)
      FALSE_TYPE = ::RBS::Types::Literal.new(literal: false, location: nil)
      BOOL_TYPE = ::RBS::Types::Bases::Bool.new(location: nil)

      def initialize(types)
        @types = types
      end

      def inject
        normalize

        uniqed = @types.uniq

        return UNTYPED if uniqed.find { |t| t == UNTYPED }

        has_true = uniqed.delete(TRUE_TYPE)
        has_false = uniqed.delete(FALSE_TYPE)
        if has_true || has_false
          uniqed << BOOL_TYPE
        end

        return UNTYPED if uniqed.empty?
        return uniqed.first if uniqed.length == 1

        args_or_other = uniqed.group_by do |type|
          type.respond_to?(:args) && !type.args.empty?
        end
        if args_or_other[true]
          # { Array => [Array[Intger], Array[String]], Hash => [Hash[untyped, untyped]], ... }
          type_by_name = args_or_other[true].group_by do |type|
            type.name
          end
          type_by_name.each do |name, types|
            if with_untyped_type = types.find { |type| type.args.include?(UNTYPED) }
              types.replace([with_untyped_type])
            end
          end
          args_injected = type_by_name.values.flatten
          args_injected.concat(args_or_other[false]) if args_or_other[false]
          uniqed = args_injected
        end

        after_optional = uniqed.delete(NIL_TYPE)
        injected = uniqed.inject do |r, type|
          case r
          when ::RBS::Types::Union
            r.tap { r.types << type }
          else
            ::RBS::Types::Union.new(types: [r, type], location: nil)
          end
        end

        if after_optional
          return ::RBS::Types::Optional.new(type: injected, location: nil)
        end

        injected
      end

      private

      def normalize
        @types = @types.map do |type|
          case type
          when String
            ::RBS::Parser.parse_type(type)
          else
            type
          end
        end

        @types = @types.map do |rbs_type|
          case rbs_type
          when ::RBS::Types::ClassInstance
            case rbs_type.name.to_s
            when 'TrueClass', '::TrueClass', 'FalseClass', '::FalseClass'
              BOOL_TYPE
            when 'NilClass', '::NilClass'
              NIL_TYPE
            else
              rbs_type
            end
          else
            rbs_type
          end
        end

        self
      end
    end
  end
end
