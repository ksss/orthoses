# frozen_string_literal: true

require_relative 'rbs_store/content'

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
  #   store.env.class_decls[TypeName("Foo::Bar")]
  class RBSStore
    include Enumerable

    def initialize
      @name_content_map = {}
    end

    def [](full_name)
      @name_content_map[full_name.to_s] ||= RBSStore::Content.new(name: full_name.to_s)
    end

    def each(...)
      @name_content_map.each(...)
    end

    def key?(full_name)
      @name_content_map.key?(full_name)
    end

    def delete(full_name)
      @name_content_map.delete(full_name)
    end

    def filter!(...)
      @name_content_map.filter!(...)
    end

    def length()
      @name_content_map.length
    end
  end
end
