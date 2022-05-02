# frozen_string_literal: true

require_relative 'rbs_store/buffer'

module Orthoses
  # Common interface for output.
  # RBSStore expect to use result of middleware.
  #   store = @loader.call(env)
  #   store["Foo::Bar"] << "def baz: () -> void"
  #   store[Foo::Bar] << "def qux: () -> void"
  # By default, RBSStore search constant of keys. and decide class or module declaration.
  # Also declaraion can specify directly.
  #   store["Foo::Bar"].decl = RBS::AST::Declarations::Class.new(...)
  # RBSStore can generate declarations and it store to RBS::Environment.
  #   store.resolve!
  #   store.env.class_decls[TypeName("Foo::Bar")]
  class RBSStore
    include Enumerable

    attr_reader :env

    def initialize
      @env = RBS::Environment.new
      @buffer_map = {}
    end

    def [](full_name)
      type_name = type_name(full_name)
      @buffer_map[type_name] ||= Buffer.new(env: @env, type_name: type_name)
    end

    def key?(full_name)
      @buffer_map.key?(full_name)
    end

    def resolve!
      @buffer_map.each_value(&:resolve!)
      @env = @env.resolve_type_names
    end

    def each(...)
      @buffer_map.each(...)
    end

    def delete(full_name)
      @buffer_map.delete(type_name(full_name))
    end

    def filter!(...)
      @buffer_map.filter!(...)
    end

    private

    def type_name(full_name)
      case full_name
      when String
        TypeName(full_name)
      when Module
        mname = Util.module_name(full_name)
        mname && TypeName(mname)
      when RBS::TypeName
        full_name
      else
        raise TypeError, "#{full_name.inspect} does not supported"
      end.absolute!
    end
  end
end
