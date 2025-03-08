require 'test_helper'

module UniqContentBodyTest
  def test_uniq_content_body(t)
    store = Orthoses::Outputable::UniqContentBody.new(->(){
      Orthoses::Utils.new_store.tap do |store|
        store["Foo"].header = "class Foo"
        store["Foo"] << "def foo: () -> void"
        store["Foo"] << "def foo: () -> void"
      end
    }).call

    actual = store["Foo"].to_rbs
    expect = <<~RBS
      class Foo
        def foo: () -> void
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
