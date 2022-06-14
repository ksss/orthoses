module DuplicationCheckerTest
  def test_update_decl(t)
    decl = RBS::Parser.parse_signature(<<~RBS).first
      class Foo
        def foo: () -> void # remove
        attr_reader foo: untyped # remove
        attr_accessor foo: untyped # remove
        alias foo to_s # alive

        attr_accessor bar: untyped # remove
        attr_accessor bar: untyped # ok

        attr_reader baz: untyped # ok
        attr_writer baz: untyped # ok
      end
    RBS
    checker = Orthoses::Content::DuplicationChecker.new(decl)
    checker.update_decl
    out = StringIO.new
    RBS::Writer.new(out: out).write_decl(decl)
    actual = out.string
    expect = <<~RBS
      class Foo
        alias foo to_s

        attr_accessor bar: untyped

        attr_reader baz: untyped
        attr_writer baz: untyped
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  def test_drop_known_method_definition(t)
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
end
