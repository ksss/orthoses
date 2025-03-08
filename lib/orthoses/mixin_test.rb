# frozen_string_literal: true

require 'test_helper'

module MixinTest
  LOADER = ->(){
    module Mod
    end
    class Foo
      prepend Mod
      extend Mod
      include Mod
      include Module.new
      include Enumerable
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
        prepend MixinTest::Mod
        extend MixinTest::Mod
        include MixinTest::Mod
        include Enumerable[untyped]
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
