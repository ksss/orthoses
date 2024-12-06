begin
  require 'test_helper'
rescue LoadError
end

module HeaderBuilderTest
  def test_module(t)
    env = Orthoses::Utils.rbs_environment(collection: false, cache: false)
    _, _, decls = RBS::Parser.parse_signature(<<~RBS)
      module Foo
        module Bar
          module Baz
          end
        end
      end
    RBS

    decls.each { env << _1 }
    header_builder = Orthoses::Content::HeaderBuilder.new(env: env)

    [
      ["Foo", "module ::Foo"],
      ["Foo::Bar", "module ::Foo::Bar"],
      ["Foo::Bar::Baz", "module ::Foo::Bar::Baz"],
    ].each do |input_name, expect_header|
      entry = env.class_decls[TypeName(input_name).absolute!] or raise "#{input_name} not found"
      output_header = header_builder.build(entry: entry)
      unless expect_header == output_header
        t.error("expect=#{expect_header}, but got #{output_header}")
      end
    end
  end

  def test_class(t)
    env = Orthoses::Utils.rbs_environment(collection: false, cache: false)
    _, _, decls = RBS::Parser.parse_signature(<<~RBS)
      class Foo
      end

      class Bar < Object
      end

      class Baz < Bar
      end

      class Qux < Struct[untyped]
      end

      class Quux < Hash[String, Integer]
      end

      class Aaa < Bbb
      end

      ClassAlias: Foo

      class SuperIsClassAlias < ClassAlias
      end
    RBS
    decls.each { env << _1 }
    header_builder = Orthoses::Content::HeaderBuilder.new(env: env)

    [
      ["BasicObject",       "class BasicObject"],
      ["Object",            "class Object < ::BasicObject"],
      ["Random",            "class Random"],
      ["Integer",           "class Integer < ::Numeric"],
      ["Array",             "class Array[unchecked out Elem]"],
      ["Foo",               "class Foo"],
      ["Bar",               "class Bar"],
      ["Baz",               "class Baz < ::Bar"],
      ["Qux",               "class Qux < ::Struct[untyped]"],
      ["Quux",              "class Quux < ::Hash[String, Integer]"],
      ["Aaa",               "class Aaa < Bbb"],
      ["SuperIsClassAlias", "class SuperIsClassAlias < ClassAlias"],
    ].each do |input_name, expect_header|
      entry = env.class_decls[TypeName(input_name).absolute!] or raise "#{input_name} not found"
      output_header = header_builder.build(entry: entry)
      unless expect_header == output_header
        t.error("expect=#{expect_header}, but got #{output_header}")
      end
    end
  end

  def test_interface(t)
    env = Orthoses::Utils.rbs_environment(collection: false, cache: false)
    _, _, decls = RBS::Parser.parse_signature(<<~RBS)
      module Mod
        interface _Foo
        end
        interface _Bar[T]
        end
      end

      interface _Foo
      end
      interface _Bar[T]
      end
    RBS
    decls.each { env << _1 }
    header_builder = Orthoses::Content::HeaderBuilder.new(env: env)

    [
      ["Mod::_Foo", "interface Mod::_Foo"],
      ["Mod::_Bar", "interface Mod::_Bar[T]"],
      ["_Foo", "interface _Foo"],
      ["_Bar", "interface _Bar[T]"],
    ].each do |input_name, expect_header|
      entry = env.interface_decls[TypeName(input_name).absolute!] or raise "#{input_name} not found"
      output_header = header_builder.build(entry: entry)
      unless expect_header == output_header
        t.error("expect=#{expect_header}, but got #{output_header}")
      end
    end
  end
end
