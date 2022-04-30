module ObjectSpaceAllTest
  module Foo
    module Bar
    end
  end

  def test_constant(t)
    store = Orthoses::ObjectSpaceAll.new(
      ->(_) { {} }
    ).call({})

    store.select! { |k, v| k.start_with?("ObjectSpaceAllTest") }

    expect = {
      "ObjectSpaceAllTest" => [],
      "ObjectSpaceAllTest::Foo" => [],
      "ObjectSpaceAllTest::Foo::Bar" => [],
    }
    unless store == expect
      t.error("[ObjectSpaceAll] expect=#{expect.inspect}, but got #{store}")
    end
  end
end
