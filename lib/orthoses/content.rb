# frozen_string_literal: true

require 'orthoses/content/duplication_checker'
require 'orthoses/content/environment'
require 'orthoses/content/header_builder'

module Orthoses
  # Common interface for output.
  # Orthoses::Content expect to use result of middleware.
  #   store = @loader.call
  #   store["Foo::Bar"] << "def baz: () -> void"
  # By default, Orthoses::Content search constant of keys.
  # and decide class or module declaration.
  # Also declaraion can specify directly.
  #   store["Foo::Bar"].header = "class Foo::Bar < Baz"
  # Orthoses::Content can generate RBS.
  #   store["Foo::Bar"].to_rbs
  class Content
    attr_reader :name
    attr_reader :body
    attr_accessor :header

    def initialize(name:)
      Orthoses.logger.debug("Create Orthoses::Content for #{name}")
      @name = name
      @body = []
      @header = nil
    end

    def <<(line)
      @body << line
    end

    def concat(other)
      @body.concat(other)
    end

    def empty?
      @body.empty?
    end

    def to_rbs
      auto_header
      uniqed_body_string
    end

    def to_decl
      auto_header
      uniqed_body_decl
    end

    private

    def original_rbs
      <<~RBS
        #{@header}
          #{@body.join("\n")}
        end
      RBS
    end

    def uniqed_body_string
      out = StringIO.new
      writer = RBS::Writer.new(out: out)
      writer.write_decl(uniqed_body_decl)
      out.string
    end

    def uniqed_body_decl
      buffer = RBS::Buffer.new(
        name: "orthoses/content.rb",
        content: original_rbs
      )
      parsed_decls = RBS::Parser.parse_signature(buffer)
      unless parsed_decls.length == 1
        raise "expect decls.length == 1, but got #{parsed_decls.length}"
      end
      parsed_decl = parsed_decls.first or raise
      parsed_decl.tap do |decl|
        DuplicationChecker.new(decl).update_decl
      end
    rescue RBS::ParsingError
      Orthoses.logger.error "```rbs\n#{original_rbs}```"
      raise
    end

    def auto_header
      env = Utils.rbs_environment(collection: true)
      if entry = env.class_decls[TypeName(name).absolute!]
        @header = Content::HeaderBuilder.new(env: env).build(entry: entry)
        return
      end

      return unless @header.nil?

      if name.split('::').last.start_with?('_')
        self.header = "interface #{name}"
        return
      end

      val = Object.const_get(name)

      case val
      when Class
        superclass =
          if val.superclass && val.superclass != Object
            super_module_name = Utils.module_name(val.superclass)

            if super_module_name && super_module_name != "Random::Base" # https://github.com/ruby/rbs/pull/977
              " < ::#{super_module_name}#{temporary_type_params(super_module_name)}"
            else
              nil
            end
          else
            nil
          end
        self.header = "class #{Utils.module_name(val)}#{type_params(name)}#{superclass}"
      when Module
        self.header = "module #{Utils.module_name(val)}#{type_params(name)}"
      else
        raise "#{val.inspect} is not class/module"
      end
    end

    def temporary_type_params(name)
      Utils.known_type_params(name)&.then do |params|
        if params.empty?
          nil
        else
          "[#{params.map { :untyped }.join(', ')}]"
        end
      end
    end

    def type_params(name)
      Utils.known_type_params(name)&.then do |type_params|
        if type_params.empty?
          nil
        else
          "[#{type_params.join(', ')}]"
        end
      end
    end
  end
end
