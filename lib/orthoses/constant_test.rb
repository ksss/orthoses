# frozen_string_literal: true

require 'test_helper'

module ConstantTest
  CONST = 0
  StructClass = Struct.new(:foo)
  const_set(:ConstSetClass, Class.new(StructClass))
  NoSuperClass = Class.new
  ModuleNew = Module.new
  module Foo
    CONST = 1
    module Bar
      CONST = 2
    end
    class Baz
      CONST = 3
      IGNORE_ME = Class.new
    end
  end

  def test_constant(t)
    store = Orthoses::Constant.new(->(){
      Orthoses::Utils.new_store.tap do |store|
        store["ConstantTest"]
      end
    }, strict: true, if: -> (current, const, val, rbs) { const.to_s != "IGNORE_ME" }).call

    unless store.length == 8
      t.error("expect 8 constant decls, but got #{store.length}")
    end

    actual = store.sort.map do |name, content|
      content.to_rbs
    end.join("\n")
    expect = <<~RBS
      module ConstantTest
        CONST: 0
      end

      class ConstantTest::ConstSetClass < ::ConstantTest::StructClass
      end

      module ConstantTest::Foo
        CONST: 1
      end

      module ConstantTest::Foo::Bar
        CONST: 2
      end

      class ConstantTest::Foo::Baz
        CONST: 3
      end

      module ConstantTest::ModuleNew
      end

      class ConstantTest::NoSuperClass
      end

      class ConstantTest::StructClass < ::Struct[untyped]
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
