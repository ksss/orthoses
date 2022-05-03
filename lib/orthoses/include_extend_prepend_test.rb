# frozen_string_literal: true

module IncludeExtendPrependTest
  LOADER = ->(_){
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

  def test_include_extend_prepend(t)
    store = Orthoses::IncludeExtendPrepend.new(
      Orthoses::Store.new(LOADER)
    ).call({})

    expect = <<~RBS
      module IncludeExtendPrependTest::Mod : ::BasicObject
      end
    RBS
    actual = store["IncludeExtendPrependTest::Mod"].to_rbs
    unless expect == actual
      t.error("expect\n```rbs\n#{expect}```\nbut got\n```rb\n#{actual}```")
    end

    expect = <<~RBS
      class IncludeExtendPrependTest::Foo
        include IncludeExtendPrependTest::Mod
        extend IncludeExtendPrependTest::Mod
        prepend IncludeExtendPrependTest::Mod
      end
    RBS
    actual = store["IncludeExtendPrependTest::Foo"].to_rbs
    unless expect == actual
      t.error("expect\n```rbs\n#{expect}```\nbut got\n```rb\n#{actual}```")
    end

    actual = store["Object"].to_rbs
    expect = <<~RBS
      class Object < ::BasicObject
        include IncludeExtendPrependTest::Mod
      end
    RBS
    unless expect == actual
      t.error("expect\n```rbs\n#{expect}```\nbut got\n```rb\n#{actual}```")
    end
  end
end
