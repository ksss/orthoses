# frozen_string_literal: true

module FilterTest
  def test_filter(t)
    store = Orthoses::Filter.new(->(_){
      {
        "Foo" => [],
        "Bar" => [],
        "Baz" => ["# Baz"],
      }
    },
    if: -> (name, content) {
      /^Ba/.match?(name) && !content.empty?
    }).call({})

    expect = { "Baz" => ["# Baz"] }
    unless store == expect
      t.error("[Filter] expect=#{expect.inspect}, but got #{store}")
    end
  end
end
