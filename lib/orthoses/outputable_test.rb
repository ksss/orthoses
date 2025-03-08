require 'test_helper'

module OutputableTest
  class Simple
    prepend Orthoses::Outputable
    def initialize(loader)
      @loader = loader
    end

    def call
      @loader.call
    end
  end

  def test_all(t)
    store = Simple.new(->(){
      Orthoses::Utils.new_store.tap do |store|
        store["Foo"] << "def foo: () -> void"
        store["Foo"] << "def foo: () -> void"

        store["Bar"].header = "module Bar"
        store["Bar"] << "def bar: () -> void"

        store["_Baz"] << "def baz: () -> void"
      end
    }).call

      store.map { |n, c| c.to_rbs }
  rescue => err
    t.error("expect to not raise error but got `#{err.inspect}`")
  end
end
