begin
  require 'test_helper'
rescue LoadError
end

module TypeListTest
  def test_inject(t)
    [
      [ [], "untyped" ],
      [ ["true"], "bool" ],
      [ ["false"], "bool" ],
      [ ["true", "false"], "bool" ],
      [ ["true", "false", "nil"], "bool?" ],
      [ ["true", "false", "nil", "untyped"], "untyped" ],
      [ ["TrueClass"], "bool"],
      [ ["FalseClass"], "bool"],
      [ ["nil"], "nil" ],
      [ ["NilClass"], "nil"],
      [ ["String"], "String" ],
      [ ["String", "true"], "String | bool" ],
      [ ["String", "Symbol"], "String | Symbol" ],
      [ ["String", "nil"], "String?" ],
      [ ["String", "NilClass"], "String?" ],
      [ ["String", "nil", "Symbol"], "(String | Symbol)?" ],
      [ ["Array[untyped]", "Array[Integer]"], "Array[untyped]" ],
      [ ["Array[String]", "Array[Integer]"], "Array[String] | Array[Integer]" ],
      [ ["Hash[untyped, untyped]", "Hash[Integer, Integer]"], "Hash[untyped, untyped]" ],
      [ ["Hash[untyped, untyped]", "Array[Integer]", "Set[String]"], "Hash[untyped, untyped] | Array[Integer] | Set[String]" ],
    ].each do |string_types, expect|
      actual = Orthoses::Utils::TypeList.new(string_types).inject
      unless actual.to_s == expect.to_s
        t.error("expect #{expect}, but got #{actual}")
      end
    end
  end
end
