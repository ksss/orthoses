# frozen_string_literal: true

begin
  require 'test_helper'
rescue LoadError
end

module DescendantsTest
  class A
  end
  class B < A
  end
  class C < B
  end
  D = Class.new(A)
  Class.new(A)

  def test_string(t)
    store = Orthoses::Descendants.new(
      Orthoses::Store.new(->{}),
      of: 'DescendantsTest::A'
    ).call

    expect = [
      "DescendantsTest::B",
      "DescendantsTest::C",
      "DescendantsTest::D"
    ]
    actual = store.keys.sort
    unless expect == actual
      t.error("expect #{expect}, But got #{actual}")
    end
  end

  def test_object(t)
    store = Orthoses::Descendants.new(
      Orthoses::Store.new(->{}),
      of: DescendantsTest::A
    ).call

    expect = [
      "DescendantsTest::B",
      "DescendantsTest::C",
      "DescendantsTest::D"
    ]
    actual = store.keys.sort
    unless expect == actual
      t.error("expect #{expect}, But got #{actual}")
    end
  end

  def test_module(t)
    begin
      Orthoses::Descendants.new(
        Orthoses::Store.new(->{}),
        of: Kernel
      ).call
    rescue => e
      unless e.message == "`of` option should be String or Class"
        t.error(e.message)
      end
    else
      t.error("expect to raise error. But nothing")
    end
  end
end
