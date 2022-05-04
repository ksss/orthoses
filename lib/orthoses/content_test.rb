# frozen_string_literal: true

module ContentTest
  class Simple
  end
  class WithSuper < Integer
  end

  def test_to_rbs(t)
    store = Orthoses::Util.new_store
    store["ContentTest::Simple"] << "CONST: Integer"
    store["ContentTest::WithSuper"]

    actual = store.map { |_, v| v.to_rbs }.join("\n")

    expect = <<~RBS
      class ContentTest::Simple
        CONST: Integer
      end

      class ContentTest::WithSuper < ::Integer
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
