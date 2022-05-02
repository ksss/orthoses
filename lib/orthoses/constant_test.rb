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
      Orthoses::RBSStore.new.tap do |store|
        store[ConstantTest]
        store[ConstantTest::Foo]
        store[ConstantTest::Foo::Bar]
        store[ConstantTest::Foo::Baz]
      end
    }
    ).call({})

    store.resolve!

    unless store.env.constant_decls.length == 4
      t.error("expect 4 constant decls, but got #{store.env.constant_decls.length}")
    end

    {
      "ConstantTest::CONST" => "0",
      "ConstantTest::Foo::CONST" => "1",
      "ConstantTest::Foo::Bar::CONST" => "2",
      "ConstantTest::Foo::Baz::CONST" => "3",
    }.each do |name, expect|
      entry = store.env.constant_decls[TypeName(name).absolute!]
      unless entry
        t.error("expect found name=#{name.inspect} in store, but nothing")
        next
      end
      unless expect == entry.decl.type.to_s
        t.error("expect=#{expect}, but got #{entry.decl.type.to_s}")
      end
    end
  end
end
