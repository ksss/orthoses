# frozen_string_literal: true

require 'test_helper'

module RBSPrototypeRuntimeTest
  class T
    module M
    end
    include M
    CONST = 1
    HASH = {}
    ARRAY = []
    def m(a)
      2
    end
    alias mm m
  end

  def test_runtime(t)
    store = Orthoses::RBSPrototypeRuntime.new(
      -> () { Orthoses::Utils.new_store },
      patterns: ['RBSPrototypeRuntimeTest::T']
    ).call

    actual = store.map { |n, c| c.to_rbs }.join("\n")
    expect = <<~RBS
      module RBSPrototypeRuntimeTest
      end

      module RBSPrototypeRuntimeTest::T::M
      end

      class RBSPrototypeRuntimeTest::T
        include RBSPrototypeRuntimeTest::T::M
        def m: (untyped a) -> untyped
        alias mm m
        ARRAY: ::Array[untyped]
        CONST: ::Integer
        HASH: ::Hash[untyped, untyped]
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  LAZY_CALL_PATTERN = -> {
    class Foo
      class Bar; end
      class Baz; end
    end
  }

  def test_lazy_call_pattern(t)
    begin
      RBSPrototypeRuntimeTest::Foo
    rescue NameError
    else
      t.error("shoud error on here")
    end

    store = Orthoses::RBSPrototypeRuntime.new(
      Orthoses::Store.new(LAZY_CALL_PATTERN),
      patterns: [
        -> do
          RBSPrototypeRuntimeTest::Foo.constants.map do |c|
            RBSPrototypeRuntimeTest::Foo.const_get(c).to_s
          end
        end
      ]
    ).call

    unless store.has_key?('RBSPrototypeRuntimeTest::Foo::Bar') && store.has_key?('RBSPrototypeRuntimeTest::Foo::Baz')
      t.error("Should build [RBSPrototypeRuntimeTest::Foo::Bar, RBSPrototypeRuntimeTest::Foo::Baz]. But not eq #{store.keys}.")
    end
  end
end
