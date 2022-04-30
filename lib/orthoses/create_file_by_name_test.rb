module CreateFileByNameTest
  module Foo
  end

  def test_create_file_by_name(t)
    Orthoses::CreateFileByName.new(
      ->(_) {
        {
          "CreateFileByNameTest::Foo" => ["# Foo"],
          "module CreateFileByNameTest::Bar[T]" => ["# Bar"],
          "class CreateFileByNameTest::Virtual::Baz" => ["# Baz"],
          "interface CreateFileByNameTest::Virtual::Virtual::_Qux" => ["# Qux"]
        }
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

      module CreateFileByNameTest
        module Foo
          # Foo
        end
      end
    CODE
    bar_expect = <<~CODE
      # header

      module CreateFileByNameTest
        module Bar[T]
          # Bar
        end
      end
    CODE
    baz_expect = <<~CODE
      # header

      module CreateFileByNameTest
        module Virtual
          class Baz
            # Baz
          end
        end
      end
    CODE
    qux_expect = <<~CODE
      # header

      module CreateFileByNameTest
        module Virtual
          module Virtual
            interface _Qux
              # Qux
            end
          end
        end
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
