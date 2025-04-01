# frozen_string_literal: true

require 'test_helper'

module ContentTest
  class Private
  end
  private_constant :Private
  class SuperIsPrivate < Private
  end

  class Simple
  end
  class WithSuper < Integer
  end
  class SuperClassIsNoName < Class.new
  end
  class Escape
  end

  def test_to_rbs(t)
    store = Orthoses::Utils.new_store
    store["ContentTest::SuperIsPrivate"]
    store["ContentTest::Simple"] << "CONST: Integer"
    store["ContentTest::WithSuper"]
    store["ContentTest::SuperClassIsNoName"]
    store["Array"]
    store["_Foo"]
    store["ContentTest::Escape"] << "def a-b: () -> void"
    store["ContentTest::Escape"] << "def self.あいうえお: () -> void"
    store["ContentTest::Escape"] << "def self?.a_[]: () -> void"
    store["ContentTest::Escape"] << "def alias_method: () -> void"
    # store["ContentTest::Escape"] << "alias b-a a-b"
    # store["ContentTest::Escape"] << "alias self.b-a self.a-b"

    store["_Bar"].header = "interface _Bar[T]"

    actual = store.map { |_, v| v.to_rbs }.join("\n")

    expect = <<~RBS
      class ContentTest::SuperIsPrivate
      end

      class ContentTest::Simple
        CONST: Integer
      end

      class ContentTest::WithSuper < ::Integer
      end

      class ContentTest::SuperClassIsNoName
      end

      class ::Array[unchecked out Elem]
      end

      interface _Foo
      end

      class ContentTest::Escape
        def `a-b`: () -> void
        def self.`あいうえお`: () -> void
        def self?.`a_[]`: () -> void
        def alias_method: () -> void
      end

      interface _Bar[T]
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
      "include Mod",
      "include Mod[String]",
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

    buffer, directives, decls = RBS::Parser.parse_signature(<<~RBS)
      module ContentTest
      end
      module Mod[T]
      end
    RBS
    env.add_signature(buffer: buffer, directives: directives, decls: decls)

    buffer, directives, decls = RBS::Parser.parse_signature(store["ContentTest::Simple"].to_rbs)
    env.add_signature(buffer: buffer, directives: directives, decls: decls)

    begin
      RBS::DefinitionBuilder.new(env: env.resolve_type_names).build_instance(RBS::TypeName.parse("::ContentTest::Simple"))
    rescue => err
      t.error("\n```rbs\n#{store["ContentTest::Simple"].to_rbs}```\n#{err.inspect}")
    end
  end

  def test_to_decl(t)
    content = Orthoses::Content.new(name: "Mod")
    content.header = "module Mod"
    content << "def foo: () -> void"

    _, _, decls = RBS::Parser.parse_signature("module Mod\ndef foo: () -> void\nend")
    expect = decls.first
    actual = content.to_decl
    unless expect == actual
      t.error("expect to same as parsed RBS, but not")
    end
  end

  def test_uniq!(t)
    content = Orthoses::Content.new(name: "Uniq")
    content.header = "module Uniq"
    content << "def foo: () -> void"
    content << "def foo: () -> void"
    content.uniq!
    unless content.body == ["def foo: () -> void"]
      t.error("expect unique body, but got #{content.body.inspect}")
    end

    content << "def foo: () -> void"
    content.uniq!
    unless content.body == ["def foo: () -> void"]
      t.error("expect unique body, but got #{content.body.inspect}")
    end
  end

  def test_direct_edit_body_on_uniq!(t)
    content = Orthoses::Content.new(name: "Uniq")
    content.header = "module Uniq"
    content.body << "def foo: () -> void"
    content.body << "def foo: () -> void"
    content.uniq!
    unless content.body == ["def foo: () -> void"]
      t.error("expect unique body, but got #{content.body.inspect}")
    end

    content.body << "def foo: () -> void"
    content.uniq!
    unless content.body == ["def foo: () -> void"]
      t.error("expect unique body, but got #{content.body.inspect}")
    end
  end

  def test_comment(t)
    content = Orthoses::Content.new(name: "Comment")
    content.comment = "# comment"
    content.header = "module Comment"
    actual = content.to_rbs
    expect = "# comment\nmodule Comment\nend\n"
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
