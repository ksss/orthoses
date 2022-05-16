# frozen_string_literal: true

require 'orthoses/content/duplication_checker'
require 'orthoses/content/environment'

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
      @name = name
      @body = []
      @header = nil
    end

    def <<(line)
      Orthoses.logger.debug("[#{name}] << #{line} on #{__FILE__}:#{__LINE__}")
      @body << line
    end

    def concat(other)
      Orthoses.logger.debug("[#{name}] concat #{other} on #{__FILE__}:#{__LINE__}")
      @body.concat(other)
    end

    def to_rbs
      if @header.nil?
        auto_header
      end
      body_uniq("#{@header}\n#{@body.map { |b| "  #{b}\n" }.join}end\n")
    end

    private

    def auto_header
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

    def body_uniq(rbs)
      buffer = RBS::Buffer.new(
        name: "orthoses/content.rb",
        content: rbs
      )
      out = StringIO.new
      writer = RBS::Writer.new(out: out)
      decls = RBS::Parser.parse_signature(buffer).map do |parsed_decl|
        parsed_decl.tap do |decl|
          duplicate_checker = DuplicationChecker.new(decl)
          decl.members.each do |member|
            duplicate_checker << member
          end
          decl.members.replace(duplicate_checker.uniq_members)
        end
      end
      writer.write(decls)
      out.string
    rescue RBS::ParsingError
      Orthoses.logger.error "```rbs\n#{rbs}```"
      raise
    end
  end
end
