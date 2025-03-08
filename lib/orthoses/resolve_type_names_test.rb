require 'test_helper'

module ResolveTypeNamesTest
  def test_middleware(t)
    store = Orthoses::Builder.new do
      use Orthoses::ResolveTypeNames
      use Orthoses::Tap do |store|
        store["Foo"].comment = "# Comment1\n# Comment2"
        store["Foo"].header = "class Foo"
        store["Foo"] << "# comment\ndef foo: (Integer) -> String"
        store["Foo"] << "def baz: (:literal) -> :literal"
        store["Foo"] << "def bar: (Not::Found) -> void"

        store["Bar"].comment = "# Comment3\n# Comment4"
        store["Bar"].header = "class Bar  < Foo"
      end
      run -> () {}
    end.call

    actual = store.map { |n, c| c.to_rbs }.join("\n")
    expect = <<~RBS
      # Comment1
      # Comment2
      class ::Foo
        # comment
        def foo: (::Integer) -> ::String
        def baz: (:literal) -> :literal
        def bar: (Not::Found) -> void
      end

      # Comment3
      # Comment4
      class ::Bar < ::Foo
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
