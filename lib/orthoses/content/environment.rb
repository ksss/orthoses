module Orthoses
  class Content
    class Environment
      class << self
        def load_from_paths(paths)
          new.tap do |env|
            paths.each do |path|
              Orthoses.logger.debug("Load #{path}")
              buffer = RBS::Buffer.new(name: path.to_s, content: File.read(path.to_s, encoding: "UTF-8"))
              _, _, decls = RBS::Parser.parse_signature(buffer)
              decls.each do |decl|
                env << decl
              end
            end
          end
        end
      end

      def initialize(
        method_definition_filter: nil,
        alias_filter: nil,
        constant_filter: nil,
        mixin_filter: nil,
        attribute_filter: nil
      )
        @load_env = RBS::Environment.new
        @known_env = Utils.rbs_environment(cache: false)
        @method_definition_filter = method_definition_filter
        @alias_filter = alias_filter
        @constant_filter = constant_filter
        @mixin_filter = mixin_filter
        @attribute_filter = attribute_filter
      end

      def <<(decl)
        begin
          @load_env << decl
          @known_env << decl
        rescue RBS::DuplicatedDeclarationError => err
          Orthoses.logger.warn(err.inspect)
        end

        self
      end

      def write_to(store:)
        each do |add_content|
          content = store[add_content.name]
          content.header = add_content.header
          content.comment ||= add_content.comment
          content.concat(add_content.body)
        end
      end

      def each
        avoid_generic_parameter_mismatch_error

        header_builder = HeaderBuilder.new(env: @known_env)

        @load_env.class_decls.each do |type_name, m_entry|
          name = type_name.relative!.to_s
          content = Content.new(name: name)
          content.comment = m_entry.primary.decl.comment&.string&.gsub(/^/, "# ")
          content.header = header_builder.build(entry: m_entry, name_hint: name)
          decls = m_entry.decls.map(&:decl)
          decls_to_lines(decls).each do |line|
            content << line
          end
          detect_mixin_and_build_content(decls).each do |mixin_content|
            yield mixin_content
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

      private

      # Avoid `RBS::GenericParameterMismatchError` from like rbs_prototype_rb
      #     class Array # <= RBS::GenericParameterMismatchError
      #     end
      def avoid_generic_parameter_mismatch_error
        @known_env.class_decls.each do |type_name, m_entry|
          tmp_primary_d = m_entry.decls.find { |d| !d.decl.type_params.empty? }
          next unless tmp_primary_d
          m_entry.decls.each do |d|
            if d.decl.type_params.empty?
              d.decl.type_params.replace(tmp_primary_d.decl.type_params)
            end
          end
        end
      end

      def detect_mixin_and_build_content(decls)
        decls.flat_map do |decl|
          decl.members.grep(RBS::AST::Members::Mixin).map do |decl|
            Content.new(name: decl.name.relative!.to_s)
          end
        end
      end

      def decls_to_lines(decls)
        out = StringIO.new
        writer = RBS::Writer.new(out: out)
        decls.each do |decl|
          next unless decl.respond_to?(:members)
          last_visibility = :public
          decl.members.each do |member|
            next if member.respond_to?(:members)
            case member
            when RBS::AST::Declarations::Constant
              next unless @constant_filter.nil? || @constant_filter.call(member)
            when RBS::AST::Members::MethodDefinition
              next unless @method_definition_filter.nil? || @method_definition_filter.call(member)
              if last_visibility == :private && member.kind != :singleton_instance
                member.instance_variable_set(:@visibility, :private)
              end
            when RBS::AST::Members::Alias
              next unless @alias_filter.nil? || @alias_filter.call(member)
            when RBS::AST::Members::Mixin
              next unless @mixin_filter.nil? || @mixin_filter.call(member)
            when RBS::AST::Members::Attribute
              next unless @attribute_filter.nil? || @attribute_filter.call(member)
              if last_visibility == :private
                member.instance_variable_set(:@visibility, :private)
              end
            when RBS::AST::Members::Public
              last_visibility = :public
              next
            when RBS::AST::Members::Private
              last_visibility = :private
              next
            end
            writer.write_member(member)
          end
        end
        out.string.each_line(chomp: true).to_a
      end
    end
  end
end
