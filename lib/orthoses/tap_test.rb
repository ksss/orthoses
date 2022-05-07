# frozen_string_literal: true

module TapTest
  def test_tap(t)
    store = Orthoses::Builder.new do
      use Orthoses::Tap do |store|
        store["Foo::Bar"].header = "class Foo::Bar"
        store["Foo::Bar"] << "def baz: () -> void"
      end
      run -> () {}
    end.call

    actual = store.map { |n, c| c.to_rbs }.join("\n")
    expect = <<~RBS
      class Foo::Bar
        def baz: () -> void
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
