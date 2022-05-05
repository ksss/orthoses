# frozen_string_literal: true

module ObjectSpaceAllTest
  module Foo
    module Bar
    end
  end

  def test_object_space_all(t)
    store = Orthoses::Builder.new do
      use Orthoses::Filter,
        if: -> (name, content) { name.to_s.start_with?("ObjectSpaceAllTest") }
      use Orthoses::ObjectSpaceAll
      run ->() {}
    end.call

    %w[
      ObjectSpaceAllTest
      ObjectSpaceAllTest::Foo
      ObjectSpaceAllTest::Foo::Bar
    ].each do |expect_key|
      unless store.key?(expect_key)
        t.error("expec to has key=#{expect_key.inspect}, but nothing")
      end
    end
  end
end
