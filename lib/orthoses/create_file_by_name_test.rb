# frozen_string_literal: true

module CreateFileByNameTest
  module Foo
  end

  def test_create_file_by_name(t)
    Orthoses::CreateFileByName.new(
      ->() {
        Orthoses::Utils.new_store.tap do |store|
          store["CreateFileByNameTest::Foo"] << "# foo"
          store["CreateFileByNameTest::Foo"] << "def foo: () -> void"

          store["CreateFileByNameTest::Bar"].tap do |content|
            content.header = "module CreateFileByNameTest::Bar[T]"
            content << "# bar"
            content << "def bar: () -> T"
          end

          store["CreateFileByNameTest::Virtual::Baz"].tap do |content|
            content.header = "class CreateFileByNameTest::Virtual::Baz"
            content << "# baz"
            content << "def baz: () -> void"
          end

          store["CreateFileByNameTest::Virtual::Virtual::_Qux"].tap do |content|
            content.header = "interface CreateFileByNameTest::Virtual::Virtual::_Qux"
            content << "# qux"
            content << "def qux: () -> void"
          end
        end
      },
      base_dir: "tmp",
      header: "# header"
    ).call

    foo = Pathname("tmp/create_file_by_name_test/foo.rbs")
    bar = Pathname("tmp/create_file_by_name_test/bar.rbs")
    baz = Pathname("tmp/create_file_by_name_test/virtual/baz.rbs")
    qux = Pathname("tmp/create_file_by_name_test/virtual/virtual/_qux.rbs")

    [foo, bar, baz, qux].each do |file|
      unless file.exist?
        t.error("file not created `#{file}`")
      end
    end

    foo_expect = <<~CODE
      # header

      module CreateFileByNameTest::Foo
        # foo
        def foo: () -> void
      end
    CODE
    bar_expect = <<~CODE
      # header

      module CreateFileByNameTest::Bar[T]
        # bar
        def bar: () -> T
      end
    CODE
    baz_expect = <<~CODE
      # header

      class CreateFileByNameTest::Virtual::Baz
        # baz
        def baz: () -> void
      end
    CODE
    qux_expect = <<~CODE
      # header

      interface CreateFileByNameTest::Virtual::Virtual::_Qux
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
