# frozen_string_literal: true

module ContentTest
  class Simple
  end
  class WithSuper < Integer
  end
  class SuperClassIsNoName < Class.new
  end

  def test_to_rbs(t)
    store = Orthoses::Utils.new_store
    store["ContentTest::Simple"] << "CONST: Integer"
    store["ContentTest::WithSuper"]
    store["ContentTest::SuperClassIsNoName"]
    store["Array"]

    actual = store.map { |_, v| v.to_rbs }.join("\n")

    expect = <<~RBS
      class ContentTest::Simple
        CONST: Integer
      end

      class ContentTest::WithSuper < ::Integer
      end

      class ContentTest::SuperClassIsNoName
      end

      class Array[unchecked out Elem]
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  def test_body_uniq(t)
    store = Orthoses::Utils.new_store
    store["ContentTest::Simple"].concat([
      "def foo: () -> Integer",
      "def foo: () -> String",
      "def self.foo: () -> Integer",
      "def self.foo: () -> String",
      "alias bar foo",
      "alias bar foo",
      "alias baz foo",
      "alias self.bar self.foo",
      "type baz = Integer",
      "type baz = String",
      "CONST: Integer",
      "CONST: String",
      "include Mod[Integer]",
      "include Mod[String]",
      "include Mod",
      "attr_reader qux: Integer",
      "attr_reader qux: String",
      "public",
      "public",
      "@instance_variable: Integer",
      "@instance_variable: String",
      "@@class_variable: Integer",
      "@@class_variable: String",
      "self.@class_instance_variable: Integer",
      "self.@class_instance_variable: String",
    ])
    loader = RBS::EnvironmentLoader.new
    env = RBS::Environment.from_loader(loader)
    RBS::Parser.parse_signature(<<~RBS).each do |decl|
      module ContentTest
      end
      module Mod[T]
      end
    RBS
      env << decl
    end
    RBS::Parser.parse_signature(store["ContentTest::Simple"].to_rbs).each do |decl|
      env << decl
    end

    begin
      RBS::DefinitionBuilder.new(env: env.resolve_type_names).build_instance(TypeName("::ContentTest::Simple"))
    rescue => err
      t.error("\n```rbs\n#{store["ContentTest::Simple"].to_rbs}```\n#{err.inspect}")
    end
  end
end
