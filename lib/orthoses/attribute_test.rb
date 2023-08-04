begin
  require 'test_helper'
rescue LoadError
end

module AttributeTest
  LOADER = ->{
    class Foo
      attr :attr
      attr_accessor :attr_accessor
      attr_reader :attr_reader
      attr_writer :attr_writer
      class << self
        attr :self_attr
        attr_accessor :self_attr_accessor
        attr_reader :self_attr_reader
        attr_writer :self_attr_writer
      end
    end
  }

  def test_attribute(t)
    store = Orthoses::Attribute.new(
      Orthoses::Store.new(LOADER)
    ).call
    actual = store["AttributeTest::Foo"].to_rbs
    expect = <<~RBS
      class AttributeTest::Foo
        attr_reader attr: untyped
        attr_accessor attr_accessor: untyped
        attr_reader attr_reader: untyped
        attr_writer attr_writer: untyped
        attr_reader self.self_attr: untyped
        attr_accessor self.self_attr_accessor: untyped
        attr_reader self.self_attr_reader: untyped
        attr_writer self.self_attr_writer: untyped
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
