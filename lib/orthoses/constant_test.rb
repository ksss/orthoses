module ConstantTest
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
    store = Orthoses::Constant.new(->(_){
      {
        "ConstantTest::Foo" => []
      }
    }).call({})

    expect = { "ConstantTest::Foo" => ["CONST: 1"] }
    unless store == expect
      t.error("[Constant] expect=#{expect.inspect}, but got #{store}")
    end
  end
end
