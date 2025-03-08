require 'test_helper'

module ConstantizableTest
  def test_delete_if_error(t)
    store = Orthoses::Outputable::ConstantizableFilter.new(->(){
      Orthoses::Utils.new_store.tap do |store|
        store["Foo"] << "def foo: () -> void"

        store["Bar"].header = "module Bar"
        store["Bar"] << "def bar: () -> void"

        store["_Baz"] << "def baz: () -> void"
      end
    }).call

    unless store.length == 2
      t.error("should delete class/module from store if NameError but not")
    end
    unless store["Bar"].body.length == 1
      t.error("If there is a header, the body should exist.")
    end
    unless store["_Baz"].body.length == 1
      t.error("If content is interface, the body should exist.")
    end
  end
end
