# frozen_string_literal: true

module MissingNameTest
  LOADER = -> {
    class C0
    end
    class C1 < C0
      class C2 < C1
      end
    end
    module M1
      module M2
      end
    end
  }
  def test_missing_name(t)
    store = Orthoses::MissingName.new(
      -> {
        LOADER.call
        Orthoses::Utils.new_store.tap do |store|
          store["MissingNameTest::M1::M2"] << "CONST: 1"
          store["MissingNameTest::C1::C2"].header = "class MissingNameTest::C1::C2 < ::MissingNameTest::C1"
        end
      }
    ).call

    unless store.has_key?("MissingNameTest::M1::M2")
      t.error("MissingNameTest::M1::M2 not found in store")
    end
    unless store["MissingNameTest::M1::M2"].header == "module MissingNameTest::M1::M2"
      t.error("MissingNameTest::M1::M2 should be module")
    end
    unless store.has_key?("MissingNameTest::M1")
      t.error("MissingNameTest::M1 not found in store")
    end
    unless store["MissingNameTest::M1"].header == "module MissingNameTest::M1"
      t.error("MissingNameTest::M1 should be module")
    end
    unless store.has_key?("MissingNameTest::C1::C2")
      t.error("MissingNameTest::C1::C2 not found in store")
    end
    unless store["MissingNameTest::C1::C2"].header == "class MissingNameTest::C1::C2 < ::MissingNameTest::C1"
      t.error("MissingNameTest::C1::C2 header should be keep")
    end
    unless store.has_key?("MissingNameTest::C1")
      t.error("MissingNameTest::C1 not found in store")
    end
    unless store["MissingNameTest::C1"].header == "class MissingNameTest::C1 < ::MissingNameTest::C0"
      t.error("MissingNameTest::C1 should be class. but got #{store["MissingNameTest::C1"].header }")
    end
    unless store["MissingNameTest::C0"].header == "class MissingNameTest::C0"
      t.error("MissingNameTest::C0 should be class")
    end
    unless store.has_key?("MissingNameTest")
      t.error("MissingNameTest not found in store")
    end
  end
end
