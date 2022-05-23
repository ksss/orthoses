module DuplicationCheckerTest
  def test_drop_known_method_definition(t)
    decl = RBS::Parser.parse_signature(<<~RBS).first
      class Array[unchecked out Elem]
        def to_s: () -> void
        def sum: () -> void
      end
    RBS
    checker = Orthoses::Content::DuplicationChecker.new(decl)
    checker.update_decl
    unless decl.members.length == 0
      t.error("expect drop core method, bot #{checker.uniq_members.length}")
    end
  end
end
