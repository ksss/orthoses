# frozen_string_literal: true

module Orthoses
  # Common interface for output.
  # Orthoses::Content expect to use result of middleware.
  #   store = @loader.call(env)
  #   store["Foo::Bar"] << "def baz: () -> void"
  #   store[Foo::Bar] << "def qux: () -> void"
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
      names = name.split('::')
      names.each_with_index do |_, index|
        val = Object.const_get(names[0, index + 1].join('::'))
        case val
        when Class
          superclass =
            if val.superclass && val.superclass != Object && val.superclass.to_s != "Random::Base"
              " < ::#{Util.module_name(val.superclass)}"
            else
              nil
            end
          self.header = "class #{Util.module_name(val)}#{superclass}"
        when Module
          self.header = "module #{Util.module_name(val)}"
        else
          raise "#{val.inspect} is not class/module"
        end
      end
    end

    def body_uniq(rbs)
      buffer = RBS::Buffer.new(
        name: "orthoses/rbs_store/content.rb",
        content: rbs
      )
      out = StringIO.new
      writer = RBS::Writer.new(out: out)
      decls = RBS::Parser.parse_signature(buffer).map do |parsed_decl|
        before_members = parsed_decl.members.dup
        parsed_decl.members.uniq! { |m| [m.class, m.respond_to?(:name) ? m.name : nil] }
        (before_members - parsed_decl.members).each do |droped_member|
          Orthoses.logger.warn("#{parsed_decl.name}::#{droped_member.name.to_s}: #{droped_member.to_s} was droped since duplication")
        end
        parsed_decl
      end
      writer.write(decls)
      out.string
    end
  end
end
