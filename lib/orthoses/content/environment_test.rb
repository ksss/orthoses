module EnvironmentTest
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
    env.write_to(store: store)

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
