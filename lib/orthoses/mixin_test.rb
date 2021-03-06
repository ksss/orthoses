# frozen_string_literal: true

module MixinTest
  LOADER = ->(){
    module Mod
    end
    class Foo
      include Mod
      extend Mod
      prepend Mod
      include Module.new
    end
    class ::Object
      include Mod
    end
  }

  def test_mixin(t)
    store = Orthoses::Mixin.new(
      Orthoses::Store.new(LOADER)
    ).call

    expect = <<~RBS
      module MixinTest::Mod
      end
    RBS
    actual = store["MixinTest::Mod"].to_rbs
    unless expect == actual
      t.error("expect\n```rbs\n#{expect}```\nbut got\n```rb\n#{actual}```")
    end

    expect = <<~RBS
      class MixinTest::Foo
        include MixinTest::Mod
        extend MixinTest::Mod
        prepend MixinTest::Mod
      end
    RBS
    actual = store["MixinTest::Foo"].to_rbs
    unless expect == actual
      t.error("expect\n```rbs\n#{expect}```\nbut got\n```rb\n#{actual}```")
    end

    actual = store["Object"].to_rbs
    expect = <<~RBS
      class Object < ::BasicObject
        include MixinTest::Mod
      end
    RBS
    unless expect == actual
      t.error("expect\n```rbs\n#{expect}```\nbut got\n```rb\n#{actual}```")
    end
  end
end
