# frozen_string_literal: true

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
      val = Object.const_get(name)

      case val
      when Class
        superclass =
          if val.superclass && val.superclass != Object
            super_module_name = Utils.module_name(val.superclass)

            if super_module_name && super_module_name != "Random::Base" # https://github.com/ruby/rbs/pull/977
              delegated_type_params = delegated_type_params(super_module_name)
              "#{delegated_type_params} < ::#{super_module_name}#{delegated_type_params}"
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

    def delegated_type_params(name)
      Utils.known_type_params(name)&.then do |params|
        if params.empty?
          nil
        else
          "[#{(:T..).take(params.length).join(', ')}]"
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
        before_members = parsed_decl.members.dup
        parsed_decl.members.uniq! { |m| [m.class, m.respond_to?(:name) ? m.name : nil] }
        (before_members - parsed_decl.members).each do |droped_member|
          Orthoses.logger.warn("#{parsed_decl.name}::#{droped_member.name.to_s}: #{droped_member.to_s} was droped since duplication")
        end
        parsed_decl
      end
      writer.write(decls)
      out.string
    rescue RBS::ParsingError
      puts "```rbs"
      puts rbs
      puts "```"
      raise
    end
  end
end
