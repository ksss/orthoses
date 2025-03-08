# frozen_string_literal: true

require 'test_helper'

module SortTest
  def test_sort(t)
    store = Orthoses::Builder.new do
      use Orthoses::Sort
      use Orthoses::Tap do |store|
        store["Foo"].header = "class Foo"
        store["Foo"] << "def foo: () -> void"
        store["Foo"] << "def baz: () -> void"
        store["Foo"] << "def bar: () -> void"
      end
      run -> () {}
    end.call

    actual = store.map { |n, c| c.to_rbs }.join("\n")
    expect = <<~RBS
      class Foo
        def bar: () -> void
        def baz: () -> void
        def foo: () -> void
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
