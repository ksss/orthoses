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
    store.resolve!

    out = StringIO.new
    writer = RBS::Writer.new(out: out)
    store.env.class_decls.each do |name, entry|
      entry.decls.each do |d|
        writer.write_decl(d.decl)
      end
    end

    expect = <<~RBS
      class ::RBSStoreTest::Simple
        ::RBSStoreTest::Simple::CONST: Integer
      end
      class ::RBSStoreTest::WithSuper < ::Integer
      end
    RBS
    unless expect == out.string
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{out.string}```\n")
    end
  end

  def test_manual_set_decl(t)
    store = Orthoses::RBSStore.new
    store["RBSStoreTest::V::SelfType"].decl = RBS::AST::Declarations::Module.new(
      name: TypeName("RBSStoreTest::V::SelfType"),
      type_params: [],
      self_types: [
        RBS::AST::Declarations::Module::Self.new(
          name: TypeName("BasicObject").absolute!,
          args: [],
          location: nil
        )
      ],
      members: [],
      annotations: [],
      location: nil,
      comment: nil
    )
    store.resolve!

    out = StringIO.new
    writer = RBS::Writer.new(out: out)
    store.env.class_decls.each do |name, entry|
      entry.decls.each do |d|
        writer.write_decl(d.decl)
      end
    end

    expect = <<~RBS
      module ::RBSStoreTest::V::SelfType : ::BasicObject
      end
    RBS
    unless expect == out.string
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{out.string}```\n")
    end
  end
end
