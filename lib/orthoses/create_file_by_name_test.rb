# frozen_string_literal: true

module CreateFileByNameTest
  module Foo
  end

  def test_create_file_by_name(t)
    Orthoses::CreateFileByName.new(
      ->(_) {
        Orthoses::RBSStore.new.tap do |store|
          store[CreateFileByNameTest::Foo] << "# foo"
          store["CreateFileByNameTest::Foo"] << "def foo: () -> void"

          store["CreateFileByNameTest::Bar"].tap do |buffer|
            buffer.decl = RBS::AST::Declarations::Module.new(
              name: TypeName("CreateFileByNameTest::Bar"),
              type_params: [RBS::AST::TypeParam.new(name: :T, variance: :invariant, upper_bound: nil, location: nil)],
              members: [],
              location: nil,
              annotations: [],
              self_types: [],
              comment: nil
            )
            buffer << "# bar"
            buffer << "def bar: () -> T"
          end

          store["CreateFileByNameTest::Virtual::Baz"].tap do |buffer|
            buffer.decl = RBS::AST::Declarations::Class.new(
              name: TypeName("CreateFileByNameTest::Virtual::Baz"),
              type_params: [],
              members: [],
              location: nil,
              annotations: [],
              super_class: nil,
              comment: nil
            )
            buffer << "# baz"
            buffer << "def baz: () -> void"
          end

          store["CreateFileByNameTest::Virtual::Virtual::_Qux"].tap do |buffer|
            buffer.decl = RBS::AST::Declarations::Interface.new(
              name: TypeName("CreateFileByNameTest::Virtual::Virtual::_Qux"),
              type_params: [],
              members: [],
              location: nil,
              annotations: [],
              comment: nil
            )
            buffer << "# qux"
            buffer << "def qux: () -> void"
          end
        end
      },
      base_dir: "tmp",
      header: "# header"
    ).call({})

    foo = Pathname("tmp/create_file_by_name_test/foo.rbs")
    bar = Pathname("tmp/create_file_by_name_test/bar.rbs")
    baz = Pathname("tmp/create_file_by_name_test/virtual/baz.rbs")
    qux = Pathname("tmp/create_file_by_name_test/virtual/virtual/_qux.rbs")

    [foo, bar, baz, qux].each do |file|
      unless file.exist?
        t.error("[CreateFileByName] file not created `#{file}`")
      end
    end

    foo_expect = <<~CODE
      # header

      module ::CreateFileByNameTest::Foo
        # foo
        def foo: () -> void
      end
    CODE
    bar_expect = <<~CODE
      # header

      module ::CreateFileByNameTest::Bar[T]
        # bar
        def bar: () -> T
      end
    CODE
    baz_expect = <<~CODE
      # header

      class ::CreateFileByNameTest::Virtual::Baz
        # baz
        def baz: () -> void
      end
    CODE
    qux_expect = <<~CODE
      # header

      interface ::CreateFileByNameTest::Virtual::Virtual::_Qux
        # qux
        def qux: () -> void
      end
    CODE

    [
      [foo.read, foo_expect],
      [bar.read, bar_expect],
      [baz.read, baz_expect],
      [qux.read, qux_expect],
    ].each do |actual, expect|
      unless actual == expect
        t.error("[CreateFileByName] expect=\n#{expect.inspect}\n but got actual=\n#{actual.inspect}\n")
      end
    end
  ensure
    Pathname("tmp").rmtree rescue nil
  end
end
