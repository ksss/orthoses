# frozen_string_literal: true

module Orthoses
  class KnownSig
    # use Orthoses::KnownSig,
    #   dir: 'known_sig'
    def initialize(loader, dir:)
      @loader = loader
      @dir = dir
    end

    def call(env)
      @loader.call(env).tap do |store|
        tmp_env = RBS::Environment.new

        paths.each do |rbs_file|
          buffer = RBS::Buffer.new(name: rbs_file.to_s, content: File.read(rbs_file, encoding: "UTF-8"))
          decls = RBS::Parser.parse_signature(buffer)
          decls.each { |decl| tmp_env << decl }
        end

        tmp_env = tmp_env.resolve_type_names

        tmp_env.class_decls.each do |name, m_entry|
          buffer = store[name]
          case decl = m_entry.decls.first.decl
          when RBS::AST::Declarations::Module
            buffer.decl = RBS::AST::Declarations::Module.new(
              name: name.relative!,
              type_params: decl.type_params,
              self_types: decl.self_types,
              members: [],
              annotations: [],
              comment: nil,
              location: nil,
            )
          when RBS::AST::Declarations::Class
            buffer.decl = RBS::AST::Declarations::Class.new(
              name: name.relative!,
              type_params: decl.type_params,
              super_class: decl.super_class,
              members: [],
              annotations: [],
              comment: nil,
              location: nil,
            )
          end
          decls_to_lines(m_entry.decls.map(&:decl)).each do |line|
            buffer << line
          end
        end

        tmp_env.interface_decls.each do |name, s_entry|
          buffer = store[name]
          decl = s_entry.decl
          buffer.decl = RBS::AST::Declarations::Interface.new(
            name: decl.name,
            type_params: decl.type_params,
            members: [],
            annotations: [],
            location: nil,
            comment: nil,
          )
          decls_to_lines([decl]).each do |line|
            buffer << line
          end
        end
      end
    end

    private

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
