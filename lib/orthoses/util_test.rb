module UtilTest
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
      actual = Orthoses::Util.rbs_defined_const?(klass, library: library)
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
      actual = Orthoses::Util.rbs_defined_class?(klass, library: library)
      unless expect == actual
        t.error("Orthoses.rbs_defined_class?(#{klass}) expect=#{expect}, but got #{actual}")
      end
    end
  end

  module Foo
  end
  class SuperIsModule < Module
  end
  autoload :LoadError, 'expect_load_error'
  CONST = 1
  SuperClassNameNil = Class.new(Class.new)
  SingletonClass = singleton_class

  def test_string_to_namespaces(t)
    [
      [
        "UtilTest::Foo",
        ["module UtilTest", "module Foo"],
      ],
      [
        "module UtilTest::Bar",
        ["module UtilTest", "module Bar"],
      ],
      [
        "class UtilTest::Baz[T]",
        ["module UtilTest", "class Baz[T]"],
      ],
      [
        "interface UtilTest::Virtual::_Qux",
        ["module UtilTest", "module Virtual", "interface _Qux"],
      ],
      [
        "UtilTest::SuperIsModule",
        ["module UtilTest", "module SuperIsModule"],
      ],
      [
        "UtilTest::SuperClassNameNil",
        ["module UtilTest", "class SuperClassNameNil"],
      ],
      [
        "Object",
        ["class Object < ::BasicObject"],
      ],
      [
        "Random",
        ["class Random"],
      ],
      [
        "Hash",
        ["class Hash[unchecked out K, unchecked out V]"],
      ],
      [
        "BasicObject",
        ["class BasicObject"],
      ],
      [
        "Enumerable",
        ["module Enumerable[unchecked out Elem]"],
      ],
    ].each do |full_name, expect|
      actual = Orthoses::Util.string_to_namespaces(full_name)
      unless expect == actual
        t.error("expect=\n#{expect.inspect}\nbut got\n#{actual.inspect} with full_name=#{full_name}")
      end
    end

    [
      ["UtilTest::CONST", Orthoses::NameSpaceError],
      ["UtilTest::NOTHING", Orthoses::ConstLoadError],
    ].each do |error_case, error_class|
      begin
        Orthoses::Util.string_to_namespaces(error_case)
      rescue => err
      end
      unless err.instance_of?(error_class)
        t.error("case=#{error_case} expect=#{error_class} but got #{err.inspect}")
      end
    end
  end

  def test_object_to_rbs(t)
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
    ].each do |object, expect|
      actual = Orthoses::Util.object_to_rbs(object)
      unless actual == expect
        t.error("expect=#{expect.inspect}, but got #{actual.inspect}")
      end
    end
  end

  def test_check_const_getable(t)
    [
      [ "Object", true ],
      [ "class Object", false, NameError ],
      [ "UtilTest::Foo", true ],
      [ "UtilTest::LoadError", false, ::LoadError ],
      [ "UtilTest::SingletonClass", false ],
    ].each do |name, expect, expect_error|
      actual_error = nil
      actual = Orthoses::Util.check_const_getable(name) do |error|
        actual_error = error
      end
      unless actual == expect
        t.error("expect=#{expect.inspect}, but got #{actual.inspect}") and next
      end
      if !!actual_error ^ !!expect_error
        t.error("expect_error=#{expect_error.inspect}, but got #{actual_error.inspect}") and next
      end
      if actual_error && expect_error && !actual_error.instance_of?(expect_error)
        t.error("expect_error=#{expect_error.inspect}, but got #{actual_error.inspect}")
      end
    end
  end
end
