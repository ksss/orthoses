# frozen_string_literal: true

begin
  require 'test_helper'
rescue LoadError
end

module ExcludeRBSTest
  def test_exclude_rbs(t)
    store = Orthoses::ExcludeRBS.new(
      -> {
        Orthoses::Utils.new_store.tap do |s|
          c = s["ExcludeRBSTest::M1"]
          c.header = "module ExcludeRBSTest::M1"
          c << "def known_method: () -> void"
          c << "def unknown_method: () -> void"
          c << "KNOWN_CONST: 1"
          c << "UNKNOWN_CONST: 1"
        end
      },
      rbs: <<~RBS
        module ExcludeRBSTest::M1
          def known_method: () -> void
          KNOWN_CONST: 1
        end
      RBS
    ).call

    expect = <<~RBS
      module ExcludeRBSTest::M1
        def unknown_method: () -> void

        UNKNOWN_CONST: 1
      end
    RBS
    actual = store["ExcludeRBSTest::M1"].to_rbs
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
