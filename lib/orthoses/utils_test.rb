# frozen_string_literal: true

module UtilsTest
  def test_rbs_defined_const?(t)
    [
      ["Object::RUBY_VERSION", nil, true],
      ["Integer", nil, false],
      ["#<Class:Integer>", nil, false],
      ["URI::HTTP::DEFAULT_PORT", nil, false],
      ["Nothing", nil, false],

      ["Object::RUBY_VERSION", 'uri', true],
      ["Integer", 'uri', false],
      ["#<Class:Integer>", 'uri', false],
      ["URI::HTTP::DEFAULT_PORT", 'uri', true],
      ["Nothing", 'uri', false],
    ].each do |klass, library, expect|
      actual = Orthoses::Utils.rbs_defined_const?(klass, library: library)
      unless expect == actual
        t.error("Orthoses.rbs_defined_const?(#{klass}) expect=#{expect}, but got #{actual}")
      end
    end
  end

  def test_rbs_defined_class?(t)
    [
      ["Object::RUBY_VERSION", nil, false],
      ["Integer", nil, true],
      ["#<Class:Integer>", nil, false],
      ["Set", nil, false],
      ["Nothing", nil, false],

      ["Object::RUBY_VERSION", 'uri', false],
      ["Integer", 'uri', true],
      ["#<Class:Integer>", 'uri', false],
      ["URI", 'uri', true],
      ["Nothing", 'uri', false],
    ].each do |klass, library, expect|
      actual = Orthoses::Utils.rbs_defined_class?(klass, library: library)
      unless expect == actual
        t.error("Orthoses.rbs_defined_class?(#{klass}) expect=#{expect}, but got #{actual}")
      end
    end
  end

  def test_object_to_rbs_with_no_strict(t)
    [
      [ Object, "singleton(Object)" ],
      [ Enumerable, "singleton(Enumerable)" ],
      [ Class, "singleton(Class)" ],
      [ Object.new, "Object" ],
      [ 123, "Integer" ],
      [ true, "true" ],
      [ false, "false" ],
      [ nil, "nil" ],
      [ 123.45, "Float" ],
      [ :sym, "Symbol" ],
      [ /a/, "Regexp" ],
      [ Set[], "Set[untyped]" ],
      [ Set[123, 234], "Set[Integer]" ],
      [ [], "Array[untyped]" ],
      [ [123, 234], "Array[Integer]" ],
      [ {}, "Hash[untyped, untyped]" ],
      [ { a: 1, b: 'c' }, 'Hash[Symbol, Integer | String]' ],
      [ { 1 => 2, 3 => 4 }, 'Hash[Integer, Integer]' ],
      [ ARGF, 'untyped' ],
    ].each do |object, expect|
      actual = Orthoses::Utils.object_to_rbs(object, strict: false)
      unless actual == expect
        t.error("expect=#{expect.inspect}, but got #{actual.inspect}")
      end
    end
  end

  def test_object_to_rbs_with_strict(t)
    [
      [ Object, "singleton(Object)" ],
      [ Enumerable, "singleton(Enumerable)" ],
      [ Class, "singleton(Class)" ],
      [ Object.new, "Object" ],
      [ 123, "123" ],
      [ true, "true" ],
      [ false, "false" ],
      [ nil, "nil" ],
      [ 123.45, "Float" ],
      [ :sym, ":sym" ],
      [ /a/, "Regexp" ],
      [ Set[], "Set[untyped]" ],
      [ Set[123, 234], "Set[123 | 234]" ],
      [ [], "Array[untyped]" ],
      [ [123, 234], "[123, 234]" ],
      [ {}, "Hash[untyped, untyped]" ],
      [ { a: 1, b: 'c' }, '{ a: 1, b: "c" }' ],
      [ { 1 => 2, 3 => 4 }, 'Hash[1 | 3, 2 | 4]' ],
      [ ARGF, 'untyped' ],
    ].each do |object, expect|
      actual = Orthoses::Utils.object_to_rbs(object, strict: true)
      unless actual == expect
        t.error("expect=#{expect.inspect}, but got #{actual.inspect}")
      end
    end
  end
end
