# frozen_string_literal: true

module ConstantTest
  CONST = 0
  module Foo
    CONST = 1
    module Bar
      CONST = 2
    end
    class Baz
      CONST = 3
    end
  end

  def test_constant(t)
    store = Orthoses::Constant.new(->(env){
      Orthoses::Util.new_store.tap do |store|
        store[ConstantTest]
        store[ConstantTest::Foo]
        store[ConstantTest::Foo::Bar]
        store[ConstantTest::Foo::Baz]
      end
    }).call({})

    unless store.length == 4
      t.error("expect 4 constant decls, but got #{store.length}")
    end

    {
      "ConstantTest" => ["CONST: 0"],
      "ConstantTest::Foo" => ["CONST: 1"],
      "ConstantTest::Foo::Bar" => ["CONST: 2"],
      "ConstantTest::Foo::Baz" => ["CONST: 3"],
    }.each do |name, expect|
      content = store[name]
      unless content
        t.error("expect found name=#{name.inspect} in store, but nothing")
        next
      end
      unless expect == content.body
        t.error("expect=#{expect}, but got #{content.body}")
      end
    end
  end
end
