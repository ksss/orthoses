# frozen_string_literal: true

module TraceMethodTest
  LOADER_METHOD = -> {
    class M
      def initialize(a)
        @a = a
      end

      def a_ten
        @a * 10
      end

      def b_ten(b)
        b * 10
      end

      def call_priv(c)
        priv(c)
      end

      def dele(*a, **k)
        priv(*a, **k)
      end

      def simple_raise
        raise
      end

      def if_raise(a)
        if a
          raise
        else
          'ok'
        end
      end

      private

      def priv(bool)
        if bool
          1
        else
          :sym
        end
      end
    end
  }
  def test_method(t)
    store = Orthoses::Trace::Method.new(->{
      LOADER_METHOD.call

      m = M.new(100)
      m.a_ten
      m.b_ten(20)
      m.call_priv(true)
      m.call_priv(false)
      m.dele(true)

      m.simple_raise rescue nil
      m.if_raise(false)
      m.if_raise(true) rescue nil

      Orthoses::Utils.new_store
    }, patterns: ['TraceMethodTest::M']).call

    actual = store.map { |n, c| c.to_rbs }.join("\n")
    expect = <<~RBS
      class TraceMethodTest::M
        private def initialize: (Integer a) -> void

        def a_ten: () -> Integer

        def b_ten: (Integer b) -> Integer

        private def priv: (bool `bool`) -> (Integer | Symbol)

        def call_priv: (bool c) -> (Integer | Symbol)

        def dele: (*Array[bool] a, **Hash[untyped, untyped]) -> Integer

        def if_raise: (bool a) -> String
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
