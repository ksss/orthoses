module EnvironmentTest
  def test_singleton_build_header(t)
    [
      ["class BasicObject",           "class BasicObject"],
      ["class Object < BasicObject",  "class Object < BasicObject"],
      ["class Random < Random::Base", "class Random"],
      ["class Integer < Numeric",     "class Integer < Numeric"],
      ["class Foo",                   "class Foo"],
      ["class Foo < Object",          "class Foo"],
      ["class Foo < Bar",             "class Foo < Bar"],
      ["class Foo < Struct[untyped]", "class Foo < Struct[untyped]"],
    ].each do |input_header, expect_header|
      decl = RBS::Parser.parse_signature("#{input_header}\nend").first
      output_header = Orthoses::Content::Environment.build_header(decl: decl)
      unless expect_header == output_header
        t.error("expect=#{expect_header}, but got #{output_header}")
      end
    end
  end
end
