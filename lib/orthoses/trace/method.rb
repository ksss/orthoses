# frozen_string_literal: true

module Orthoses
  class Trace
    class Method
      # internal
      Info = Struct.new(:key, :op_name_types, :raised, keyword_init: true)
      include Targetable

      def initialize(loader, patterns:)
        @loader = loader
        @patterns = patterns

        @stack = []
        @args_return_map = Hash.new { |h, k| h[k] = [] }
      end

      def call
        build_trace_point.enable do
          @loader.call
        end.tap do |store|
          build_members.each do |(mod_name, member)|
            out = StringIO.new
            writer = ::RBS::Writer.new(out: out)
            writer.write_member(member)
            store[mod_name] << out.string
          end
        end
      end

      private

      def build_trace_point
        TracePoint.new(:call, :return, :raise) do |tp|
          if tp.defined_class.singleton_class?
            mod_name = Utils.module_name(tp.defined_class) or next
            kind = :singleton
          else
            mod_name = Utils.module_name(tp.defined_class) or next
            kind = :instance
          end

          next unless target?(mod_name)

          visibility = tp.self.private_methods.include?(tp.method_id) ? :private : nil
          key = [mod_name, kind, visibility, tp.method_id]

          case tp.event
          when :call
            op_name_types = tp.parameters.map do |op, name|
              case name
              when nil, :*, :**, :&
                [op, name, 'untyped']
              else
                type = Utils.object_to_rbs(tp.binding.local_variable_get(name))
                [op, name, type]
              end
            end

            @stack.push(Info.new(key: key, op_name_types: op_name_types))
          when :raise
            @stack.last.raised = true
          when :return
            info = @stack.pop
            if !info.raised
              @args_return_map[info.key] << [info.op_name_types, Utils.object_to_rbs(tp.return_value)]
            end
          end
        end
      end

      def build_members
        untyped = ::RBS::Types::Bases::Any.new(location: nil)

        members = @args_return_map.map do |(mod_name, kind, visibility, method_id), type_samples|
          type_samples.uniq!
          method_types = type_samples.map do |(op_name_types, return_type)|
            required_positionals = []
            optional_positionals = []
            rest = nil
            trailing_positionals = []
            required_keywords = {}
            optional_keywords = {}
            rest_keywords = nil

            requireds = required_positionals

            block = nil

            op_name_types.each do |op, name, string_type|
              type = ::RBS::Parser.parse_type(string_type)

              case op
              when :req
                requireds << ::RBS::Types::Function::Param.new(name: name, type: type)
              when :opt
                requireds = trailing_positionals
                optional_positionals << ::RBS::Types::Function::Param.new(name: name, type: type)
              when :rest
                requireds = trailing_positionals
                name = nil if name == :* # For `def f(...) end` syntax
                rest = ::RBS::Types::Function::Param.new(name: name, type: type)
              when :keyreq
                required_keywords[name] = ::RBS::Types::Function::Param.new(name: nil, type: type)
              when :key
                optional_keywords[name] = ::RBS::Types::Function::Param.new(name: nil, type: type)
              when :keyrest
                rest_keywords = ::RBS::Types::Function::Param.new(name: nil, type: type)
              when :block
                block = ::RBS::Types::Block.new(
                  type: ::RBS::Types::Function.empty(untyped).update(rest_positionals: ::RBS::Types::Function::Param.new(name: nil, type: untyped)),
                  required: false,
                  self_type: nil
                )
              end
            end

            return_type = if method_id == :initialize
              ::RBS::Types::Bases::Void.new(location: nil)
            else
              ::RBS::Parser.parse_type(return_type)
            end

            ::RBS::MethodType.new(
              location: nil,
              type_params: [],
              type: ::RBS::Types::Function.new(
                required_positionals: required_positionals,
                optional_positionals: optional_positionals,
                rest_positionals: rest,
                trailing_positionals: trailing_positionals,
                required_keywords: required_keywords,
                optional_keywords: optional_keywords,
                rest_keywords: rest_keywords,
                return_type: return_type,
              ),
              block: block
            )
          end

          # from:
          #   def foo: () -> true
          #          | () -> false
          #          | (Integer) -> Integer
          # to:
          #   def foo: () -> bool
          #          | (Integer) -> Integer
          functions_without_return_type_map = method_types.group_by do |method_type|
            method_type.type.with_return_type(untyped)
          end
          types = functions_without_return_type_map.map do |func, method_types_by_arg|
            injected = Utils::TypeList.new(method_types_by_arg.map(&:type).map(&:return_type)).inject
            method_type = method_types_by_arg.first
            method_type.update(type: method_type.type.with_return_type(injected))
          end

          [
            mod_name,
            RBS::AST::Members::MethodDefinition.new(
              annotations: [],
              comment: nil,
              kind: kind,
              location: nil,
              name: method_id,
              overload: false,
              types: types,
              visibility: visibility
            )
          ]
        end
      end
    end
  end
end
