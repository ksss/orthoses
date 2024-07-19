# frozen_string_literal: true

begin
  require 'test_helper'
rescue LoadError
end

module TraceAttributeTest
  LOADER_ATTRIBUTE = ->{
    class Foo
      class Bar
        attr_accessor :attr_acce_publ
      end

      class Baz
        attr_accessor :multi_types
      end

      attr_accessor :attr_acce_publ
      attr_reader :attr_read_publ
      attr_writer :attr_writ_publ
      class << self
        attr_accessor :self_attr_acce_publ
      end

      attr_accessor :attr_acce_priv

      private :attr_acce_priv

      def initialize
        @attr_acce_publ = :sym
        @attr_read_publ = :sym
        self.attr_acce_priv = 123
        self.attr_acce_priv
      end
    end
  }

  def test_attribute(t)
    store = Orthoses::Trace::Attribute.new(->{
      LOADER_ATTRIBUTE.call
      foo = Foo.new
      foo.attr_acce_publ
      foo.attr_acce_publ = "str"
      foo.attr_read_publ
      foo.attr_writ_publ = 123

      Foo.self_attr_acce_publ
      Foo.self_attr_acce_publ = 123

      Foo::Bar.new.attr_acce_publ = /reg/

      Orthoses::Utils.new_store
    }, patterns: ['TraceAttributeTest::Foo*']).call

    actual = store.map { |n, c| c.to_rbs }.join("\n")
    expect = <<~RBS
      class TraceAttributeTest::Foo
        attr_accessor attr_acce_priv: Integer
        attr_accessor attr_acce_publ: String | Symbol
        attr_reader attr_read_publ: Symbol
        attr_writer attr_writ_publ: Integer
        attr_accessor self.self_attr_acce_publ: Integer?
      end

      class TraceAttributeTest::Foo::Bar
        attr_accessor attr_acce_publ: Regexp
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  def test_union_sort(t)
    store1 = Orthoses::Trace::Attribute.new(->{
      LOADER_ATTRIBUTE.call
      baz = Foo::Baz.new
      baz.multi_types = 0
      baz.multi_types = '1'

      Orthoses::Utils.new_store
    }, patterns: ['TraceAttributeTest::Foo::Baz']).call

    store2 = Orthoses::Trace::Attribute.new(->{
      LOADER_ATTRIBUTE.call
      baz = Foo::Baz.new
      baz.multi_types = '1'
      baz.multi_types = 0

      Orthoses::Utils.new_store
    }, patterns: ['TraceAttributeTest::Foo::Baz']).call

    expect = store1.map { _2.to_rbs }.join("\n")
    actual = store2.map { _2.to_rbs }.join("\n")
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  def test_without_union_sort(t)
    store = Orthoses::Trace::Attribute.new(->{
      LOADER_ATTRIBUTE.call
      baz = Foo::Baz.new
                            # The order of the union types will be the following
      baz.multi_types = '1' # String
      baz.multi_types = 0   # Integer

      Orthoses::Utils.new_store
    }, patterns: ['TraceAttributeTest::Foo::Baz'], sort_union_types: false).call

    expect = store.map { _2.to_rbs }.join("\n")
    actual = <<~RBS
      class TraceAttributeTest::Foo::Baz
        attr_accessor multi_types: String | Integer
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
