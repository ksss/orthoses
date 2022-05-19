module DuplicationCheckerTest
  def test_drop_known_method_definition(t)
    decl = RBS::Parser.parse_signature("class Array[unchecked out Elem]\nend").first
    checker = Orthoses::Content::DuplicationChecker.new(decl)

    RBS::Parser.parse_signature(<<~RBS).each do |decl|
      class Array[unchecked out Elem]
        def to_s: () -> void
        def sum: () -> void
      end
    RBS

      decl.members.each do |member|
        checker << member
      end
    end

    unless checker.uniq_members.length == 0
      t.error("expect drop core method, bot #{checker.uniq_members.length}")
    end
  end
end
