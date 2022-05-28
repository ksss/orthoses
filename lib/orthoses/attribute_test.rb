module AttributeTest
  LOADER = ->{
    class Foo
      attr :attr
      attr_accessor :attr_accessor
      attr_reader :attr_reader
      attr_writer :attr_writer
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
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
