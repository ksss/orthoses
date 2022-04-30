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
    expect = {
      "module IncludeExtendPrependTest::Mod : BasicObject" => [],
      "IncludeExtendPrependTest::Foo" => [
        "include IncludeExtendPrependTest::Mod",
        "extend IncludeExtendPrependTest::Mod",
        "prepend IncludeExtendPrependTest::Mod",
      ],
      "Object" => ["include IncludeExtendPrependTest::Mod"],
    }
    unless store == expect
      t.error("[IncludeExtendPrepend] expect=\n#{expect.inspect}, but got \n#{store.inspect}")
    end
  end
end
