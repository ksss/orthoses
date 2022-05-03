# frozen_string_literal: true

module RBSStoreTest
  class Simple
  end
  class WithSuper < Integer
  end

  def test_auto_set_decl(t)
    store = Orthoses::RBSStore.new
    store["RBSStoreTest::Simple"] << "CONST: Integer"
    store["RBSStoreTest::WithSuper"]

    actual = store.map { _2.to_rbs }.join("\n")

    expect = <<~RBS
      class RBSStoreTest::Simple
        CONST: Integer
      end

      class RBSStoreTest::WithSuper < ::Integer
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
