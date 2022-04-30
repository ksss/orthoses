module FilterTest
  def test_filter(t)
    store = Orthoses::Filter.new(->(_){
      {
        "Foo" => [],
        "Bar" => [],
        "Baz" => ["# Baz"],
      }
    },
    if: -> (name, bodies) {
      /^Ba/.match?(name) && !bodies.empty?
    }).call({})

    expect = { "Baz" => ["# Baz"] }
    unless store == expect
      t.error("[Filter] expect=#{expect.inspect}, but got #{store}")
    end
  end
end
