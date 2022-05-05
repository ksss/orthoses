# frozen_string_literal: true

module Orthoses
  class Load
    # use Orthoses::Load,
    #   dir: 'known_sig'
    def initialize(loader, dir:)
      @loader = loader
      @dir = dir
    end

    def call
      @loader.call.tap do |store|
        tmp_env = RBS::Environment.new

        paths.each do |rbs_file|
          Orthoses.logger.debug("Load #{rbs_file}")
          buffer = RBS::Buffer.new(name: rbs_file.to_s, content: File.read(rbs_file, encoding: "UTF-8"))
          decls = RBS::Parser.parse_signature(buffer)
          decls.each { |decl| tmp_env << decl }
        end

        # tmp_env = tmp_env.resolve_type_names

        tmp_env.class_decls.each do |type_name, m_entry|
          name = type_name.relative!.to_s
          content = store[name]
          case decl = m_entry.decls.first.decl
          when RBS::AST::Declarations::Module
            self_types = decl.self_types.empty? ? nil : " : #{decl.self_types.join(', ')}"
            content.header = "module #{name_and_params(name, decl.type_params)}#{self_types}"
          when RBS::AST::Declarations::Class
            super_class = decl.super_class.nil? ? nil : " < #{name_and_args(decl.super_class.name, decl.super_class.args)}"
            content.header = "class #{name_and_params(name, decl.type_params)}#{super_class}"
          end
          decls_to_lines(m_entry.decls.map(&:decl)).each do |line|
            content << line
          end
        end

        tmp_env.interface_decls.each do |type_name, s_entry|
          name = type_name.relative!.to_s
          content = store[name]
          decl = s_entry.decl
          content.header = "interface #{name_and_params(name, decl.type_params)}"
          decls_to_lines([decl]).each do |line|
            content << line
          end
        end
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

    def paths
      Dir.glob("#{@dir}/**/*.rbs")
    end

    def decls_to_lines(decls)
      out = StringIO.new
      writer = RBS::Writer.new(out: out)
      decls.each do |decl|
        if decl.respond_to?(:members)
          decl.members.each do |member|
            next if member.respond_to?(:members)
            writer.write_member(member)
          end
        end
      end
      out.string.each_line(chomp: true).to_a
    end
  end
end
