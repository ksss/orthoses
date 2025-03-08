require 'test_helper'

module DuplicationCheckerTest
  def test_update_decl(t)
    buffer, directives, decls = RBS::Parser.parse_signature(<<~RBS)
      class Foo
        CONST1: 1
        CONST2: 2
        CONST3: 3

        def foo: () -> void # remove
        attr_reader foo: untyped # remove
        alias foo to_s # alive

        attr_accessor bar: untyped # remove
        def bar: () -> untyped # remove
        def bar=: (untyped) -> untyped # remove
        attr_accessor bar: untyped # ok

        def self.a: () -> untyped # remove
        def self.a=: (untyped) -> untyped # remove

        attr_reader baz: untyped # ok
        attr_writer baz: untyped # ok

        def qux: () -> String # ok
        def qux: (String) -> Integer # ok
               | ...
        def qux: (String) -> Integer # ok
               | ...

        include Bar # remove
        include Bar # ok

        def inter: () -> void # remove

        def mod_func: () -> void # remove
        def self.mod_func: () -> void # remove
        def self?.mod_func: () -> void # ok

        def mod_func_env: () -> void # remove
        def self.mod_func_env: () -> void # remove
      end
    RBS
    decl = decls.first
    env = RBS::Environment.from_loader(RBS::EnvironmentLoader.new)
    buffer, directives, decls = RBS::Parser.parse_signature(<<~RBS)
      ::Foo::CONST1: 1

      class Foo
        attr_accessor self.a: untyped # ok
        CONST3: 3
        interface _I
          def inter: () -> void
        end
        include _I

        def self?.mod_func_env: () -> void
      end
    RBS
    env.add_signature(buffer: buffer, directives: directives, decls: decls)
    checker = Orthoses::Content::DuplicationChecker.new(decl, env: env.resolve_type_names)
    checker.update_decl
    out = StringIO.new
    RBS::Writer.new(out: out).write_decl(decl)
    actual = out.string
    expect = <<~RBS
      class Foo
        CONST2: 2

        alias foo to_s

        attr_accessor bar: untyped

        attr_reader baz: untyped
        attr_writer baz: untyped

        def qux: () -> String
        def qux: (String) -> Integer
               | ...
        def qux: (String) -> Integer
               | ...

        include Bar

        def self?.mod_func: () -> void
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  def test_drop_known_method_definition_method(t)
    _, _, decls = RBS::Parser.parse_signature(<<~RBS)
      class Array[unchecked out Elem]
        def to_s: () -> void
        def sum: () -> void
      end
    RBS
    decl = decls.first
    checker = Orthoses::Content::DuplicationChecker.new(decl)
    checker.update_decl
    unless decl.members.length == 0
      t.error("expect drop core method, bot #{decl.members.length}")
    end
  end

  def test_drop_known_method_definition_const_in_class(t)
    _, _, decls = RBS::Parser.parse_signature(<<~RBS)
      class IO::Buffer
        BIG_ENDIAN: Integer
      end
    RBS
    decl = decls.first
    checker = Orthoses::Content::DuplicationChecker.new(decl)
    checker.update_decl
    unless decl.members.length == 0
      t.error("expect drop core const, bot #{decl.members.length}")
    end
  end

  def test_drop_known_method_definition_single_const(t)
    _, _, decls = RBS::Parser.parse_signature(<<~RBS)
      class Complex
        I: Complex
      end
    RBS
    decl = decls.first
    checker = Orthoses::Content::DuplicationChecker.new(decl)
    checker.update_decl
    unless decl.members.length == 0
      t.error("expect drop core const, bot #{decl.members.length}")
    end
  end
end
