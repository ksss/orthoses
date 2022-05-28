module LoadRBSTest
  def test_load_rbs_test(t)
    store = Orthoses::LoadRBS.new(
      ->{ Orthoses::Utils.new_store },
      paths: [File.expand_path("../../known_sig/orthoses.rbs", __dir__)]
    ).call

    expect = <<~RBS
      module Orthoses
        VERSION: String

        attr_accessor self.logger: ::Logger

        type store = Hash[String, Orthoses::Content]
      end
    RBS
    actual = store["Orthoses"].to_rbs
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end

    expect = <<~RBS
      class Orthoses::ConstLoadError < ::StandardError
        attr_reader root: Module
        attr_reader const: Symbol
        attr_reader error: untyped
        def initialize: (root: Module, const: Symbol, error: untyped) -> void
      end
    RBS
    actual = store["Orthoses::ConstLoadError"].to_rbs
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end

    expect = <<~RBS
      class Orthoses::NameSpaceError < ::StandardError
      end
    RBS
    actual = store["Orthoses::NameSpaceError"].to_rbs
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end

    expect = <<~RBS
      interface Orthoses::_Call
        def call: () -> Hash[String, Orthoses::Content]
      end
    RBS
    actual = store["Orthoses::_Call"].to_rbs
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end

    expect = <<~RBS
      interface Orthoses::_MiddleWare
        include Orthoses::_Call
      end
    RBS
    actual = store["Orthoses::_MiddleWare"].to_rbs
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
