# frozen_string_literal: true

begin
  require 'test_helper'
rescue LoadError
end

module RBSPrototypeRuntimeTest
  class T
    module M
    end
    include M
    CONST = 1
    def m(a)
      2
    end
    alias mm m
  end

  def test_runtime(t)
    store = Orthoses::RBSPrototypeRuntime.new(
      -> () { Orthoses::Utils.new_store },
      patterns: ['RBSPrototypeRuntimeTest::*']
    ).call

    actual = store.map { |n, c| c.to_rbs }.join("\n")
    expect = <<~RBS
      module RBSPrototypeRuntimeTest
      end

      class RBSPrototypeRuntimeTest::T
        include RBSPrototypeRuntimeTest::T::M
        def m: (untyped a) -> untyped
        alias mm m
        CONST: Integer
      end

      module RBSPrototypeRuntimeTest::T::M
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
