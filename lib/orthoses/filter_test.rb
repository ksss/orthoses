# frozen_string_literal: true

require 'test_helper'

module FilterTest
  def test_filter(t)
    store = Orthoses::Filter.new(->(){
      {
        "Foo" => [],
        "Bar" => [],
        "Baz" => ["# Baz"],
      }
    }) do |name, content|
      /^Ba/.match?(name) && !content.empty?
    end.call

    expect = { "Baz" => ["# Baz"] }
    unless store == expect
      t.error("[Filter] expect=#{expect.inspect}, but got #{store}")
    end
  end

  def test_error(t)
    Orthoses::Filter.new(->(){})
  rescue
    # skip
  else
    t.error("expect raise error")
  end
end
