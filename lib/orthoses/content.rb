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
    attr_accessor :comment

    def initialize(name:)
      Orthoses.logger.debug("Create Orthoses::Content for #{name}")
      @name = name
      @body = []
      @header = nil
      @comment = nil
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

    def interface?
      @name.split('::').last.start_with?('_')
    end

    def delete(val)
      @body.delete(val)
    end

    def to_rbs
      auto_header
      uniqed_body_string
    end

    def to_decl
      auto_header
      uniqed_body_decl
    end

    def uniq!
      lines = decl_to_lines(to_decl)
      @body.replace(lines)
    end

    def sort!
      require 'rbs/sorter'
      sorter = ::RBS::Sorter.new(nil, stdout: nil)
      decl = to_decl
      decl = sorter.sort_decl(decl)
      lines = decl_to_lines(decl)
      @body.replace(lines)
    end

    def original_rbs
      io = StringIO.new
      io.puts @comment if @comment
      io.puts @header
      @body.each do |line|
        io.puts "  #{line}"
      end
      io.puts "end"
      io.string
    end

    def auto_header
      env = Utils.rbs_environment
      if entry = env.class_decls[RBS::TypeName.parse(name).absolute!]
        @header = Content::HeaderBuilder.new(env: env).build(entry: entry)
        return
      end

      return unless @header.nil?

      if interface?
        self.header = "interface #{name}"
        return
      end

      val = Object.const_get(name)

      case val
      when Class
        self.header = "class #{Utils.module_name(val)}#{type_params(name)}#{build_super_class(val)}"
      when Module
        self.header = "module #{Utils.module_name(val)}#{type_params(name)}"
      else
        raise "#{val.inspect} is not class/module"
      end
    end

    private

    def build_super_class(val)
      return nil unless val.superclass && val.superclass != Object

      super_module_name = Utils.module_name(val.superclass)
      return nil unless super_module_name

      begin
        # check private const
        eval("::#{val.superclass.to_s}")
      rescue NameError
        return nil
      end

      # https://github.com/ruby/rbs/pull/977
      return nil unless super_module_name != "Random::Base"

      " < ::#{super_module_name}#{temporary_type_params(super_module_name)}"
    end

    class ArrayIO
      def initialize
        @outs = []
      end

      def puts(line = nil)
        @outs << (line || '')
      end

      def to_a
        @outs
      end
    end
    private_constant :ArrayIO

    def decl_to_lines(decl)
      out = ArrayIO.new
      writer = RBS::Writer.new(out: out)
      decl.members.each do |member|
        writer.write_member(member)
      end
      out.to_a
    end

    def uniqed_body_string
      out = StringIO.new
      writer = RBS::Writer.new(out: out)
      writer.write_decl(uniqed_body_decl)
      out.string
    end

    def uniqed_body_decl
      parsed_decls = begin
        parse(original_rbs)
      rescue RBS::ParsingError => e
        begin
          # retry with escape
          Orthoses.logger.debug "Try to parse original rbs but ParsingError"
          Orthoses.logger.debug e.message
          Orthoses.logger.debug "```rbs\n#{original_rbs}```"
          parse(escaped_rbs)
        rescue RBS::ParsingError
          # giveup
          Orthoses.logger.error "Try to parse escaped rbs"
          Orthoses.logger.error "```rbs\n#{escaped_rbs}```"
          raise
        end
      end

      unless parsed_decls.length == 1
        raise "expect decls.length == 1, but got #{parsed_decls.length}"
      end
      parsed_decl = parsed_decls.first or raise
      parsed_decl.tap do |decl|
        DuplicationChecker.new(decl).update_decl
      end
    end

    def escaped_rbs
      rbs = original_rbs
      rbs.gsub!(/def\s+(self\??\.)?(.+?):/) { "def #{$1}`#{$2}`:" }
      rbs.gsub!(/alias\s+(self\.)?(.+?)\s+(self\.)?(.+)$/) { "alias #{$1}`#{$2}` #{$3}`#{$4}`" }
      rbs.gsub!(/attr_(reader|writer|accessor)\s+(self\.)?(.+)\s*:\s*(.+)$/) { "attr_#{$1} #{$2}`#{$3}`: #{$4}" }
      rbs
    end

    def parse(rbs)
      rbs.then { |wraped| RBS::Buffer.new(name: "orthoses/content.rb", content: rbs) }
        .then { |buffer| RBS::Parser.parse_signature(buffer) }
        .then { |_, _, decls| decls }
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
