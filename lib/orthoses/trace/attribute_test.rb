# frozen_string_literal: true

module TraceAttributeTest
  LOADER_ATTRIBUTE = ->{
    class Foo
      class Bar
        attr_accessor :attr_acce_publ
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
        attr_accessor attr_acce_publ: Symbol | String
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
end
