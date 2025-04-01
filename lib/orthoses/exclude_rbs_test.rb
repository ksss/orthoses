# frozen_string_literal: true

require 'test_helper'

module ExcludeRBSTest
  def test_exclude_rbs(t)
    store = Orthoses::ExcludeRBS.new(
      -> {
        Orthoses::Utils.new_store.tap do |s|
          c = s["ExcludeRBSTest"]
          c.header = "module ExcludeRBSTest"
          c << "def known_method_outer: () -> void"
          c << "def unknown_method_outer: () -> void"
          c << "KNOWN_CONST_OUTER: 1"
          c << "UNKNOWN_CONST_OUTER: 1"

          c = s["ExcludeRBSTest::M1"]
          c.header = "module ExcludeRBSTest::M1"
          c << "def known_method: () -> void"
          c << "def unknown_method: () -> void"
          c << "KNOWN_CONST: 1"
          c << "UNKNOWN_CONST: 1"
        end
      },
      rbs: <<~RBS
        module ExcludeRBSTest
          def known_method_outer: () -> void
          KNOWN_CONST_OUTER: 1

          module M1
            def known_method: () -> void
            KNOWN_CONST: 1
          end
        end
      RBS
    ).call

    # RBS::Environment#insert_decl resolve namespace as root by default.
    expect = <<~RBS
      module ::ExcludeRBSTest::M1
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
