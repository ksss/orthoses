# frozen_string_literal: true

module IncludeExtendPrependTest
  LOADER = ->(_){
    module Mod
    end
    class Foo
      include Mod
      extend Mod
      prepend Mod
      include Module.new
    end
    class ::Object
      include Mod
    end
  }

  def test_include_extend_prepend(t)
    store = Orthoses::IncludeExtendPrepend.new(
      Orthoses::Store.new(LOADER)
    ).call({})
    store.resolve!

    entry = store.env.class_decls[TypeName("::IncludeExtendPrependTest::Mod")]
    expect = <<~RBS
      module ::IncludeExtendPrependTest::Mod : ::BasicObject
      end
    RBS
    unless expect == entey_to_rbs(entry)
      t.error("expect\n```rbs\n#{expect}```\nbut got\n```rb\n#{entey_to_rbs(entry)}```")
    end

    entry = store.env.class_decls[TypeName("::IncludeExtendPrependTest::Foo")]
    expect = <<~RBS
      class ::IncludeExtendPrependTest::Foo
        include IncludeExtendPrependTest::Mod
        extend IncludeExtendPrependTest::Mod
        prepend IncludeExtendPrependTest::Mod
      end
    RBS
    unless expect == entey_to_rbs(entry)
      t.error("expect\n```rbs\n#{expect}```\nbut got\n```rb\n#{entey_to_rbs(entry)}```")
    end

    entry = store.env.class_decls[TypeName("::Object")]
    expect = <<~RBS
      class ::Object < ::BasicObject
        include IncludeExtendPrependTest::Mod
      end
    RBS
    unless expect == entey_to_rbs(entry)
      t.error("expect\n```rbs\n#{expect}```\nbut got\n```rb\n#{entey_to_rbs(entry)}```")
    end
  end

  private

  def entey_to_rbs(entry)
    return nil unless entry
    out = StringIO.new
    writer = RBS::Writer.new(out: out)
    writer.write(entry.decls.map(&:decl))
    out.string
  end
end
