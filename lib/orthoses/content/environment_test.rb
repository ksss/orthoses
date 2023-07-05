module EnvironmentTest
  def test_visibility(t)
    input = <<~RBS
      module Bar
      end
      class Foo
        def publ1: () -> void
      end
      class Foo
        private
        def priv: () -> void
        include Bar
      end
      class Foo
        def publ2: () -> void
      end
    RBS
    env = Orthoses::Content::Environment.new
    _, _, decls = RBS::Parser.parse_signature(input)
    decls.each do |decl|
      env << decl
    end
    store = Orthoses::Utils.new_store
    env.write_to(store: store)

    expect = <<~RBS
      class Foo
        def publ1: () -> void
        private def priv: () -> void
        include Bar
        def publ2: () -> void
      end
    RBS
    actual = store["Foo"].to_rbs
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  def test_name_resolving(t)
    input = <<~RUBY
      class Foo
        class Bar
        end
        class Baz
        end
        class Baz < Bar
        end
      end
      class Array
      end
    RUBY
    env = Orthoses::Content::Environment.new
    RBS::Prototype::RB.new.then do |parser|
      parser.parse(input)
      parser.decls.each do |decl|
        env << decl
      end
    end
    store = Orthoses::Utils.new_store
    store["Foo::Bar"].header = "class Foo::Bug"
    env.write_to(store: store)
    unless store["Foo::Bar"].header == "class Foo::Bar"
      t.error("header should overwrite by env")
    end

    expect = <<~RBS
      class Foo::Baz < ::Foo::Bar
      end
    RBS
    actual = store["Foo::Baz"].to_rbs
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
