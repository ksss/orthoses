module DuplicationCheckerTest
  def test_update_decl(t)
    decl = RBS::Parser.parse_signature(<<~RBS).first
      class Foo
        CONST1: 1
        CONST2: 2
        CONST3: 3

        def foo: () -> void # remove
        attr_reader foo: untyped # remove
        attr_accessor foo: untyped # remove
        alias foo to_s # alive

        attr_accessor bar: untyped # remove
        attr_accessor bar: untyped # ok

        attr_reader baz: untyped # ok
        attr_writer baz: untyped # ok

        def qux: () -> String # ok
        def qux: (String) -> Integer # ok
               | ...

        include Bar # remove
        include Bar # ok
      end
    RBS
    env = RBS::Environment.new
    RBS::Parser.parse_signature(<<~RBS).each { env << _1 }
      ::Foo::CONST1: 1

      class Foo
        CONST3: 3
      end
    RBS
    checker = Orthoses::Content::DuplicationChecker.new(decl, env: env)
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

        include Bar
        def qux: (String) -> Integer
               | ...
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  def test_drop_known_method_definition_method(t)
    decl = RBS::Parser.parse_signature(<<~RBS).first
      class Array[unchecked out Elem]
        def to_s: () -> void
        def sum: () -> void
      end
    RBS
    checker = Orthoses::Content::DuplicationChecker.new(decl)
    checker.update_decl
    unless decl.members.length == 0
      t.error("expect drop core method, bot #{decl.members.length}")
    end
  end

  def test_drop_known_method_definition_const_in_class(t)
    decl = RBS::Parser.parse_signature(<<~RBS).first
      class IO::Buffer
        BIG_ENDIAN: Integer
      end
    RBS
    checker = Orthoses::Content::DuplicationChecker.new(decl)
    checker.update_decl
    unless decl.members.length == 0
      t.error("expect drop core const, bot #{decl.members.length}")
    end
  end

  def test_drop_known_method_definition_single_const(t)
    decl = RBS::Parser.parse_signature(<<~RBS).first
      class Complex
        I: Complex
      end
    RBS
    checker = Orthoses::Content::DuplicationChecker.new(decl)
    checker.update_decl
    unless decl.members.length == 0
      t.error("expect drop core const, bot #{decl.members.length}")
    end
  end
end
