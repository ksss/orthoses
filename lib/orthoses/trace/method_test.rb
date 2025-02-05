# frozen_string_literal: true

module TraceMethodTest
  LOADER_METHOD = -> {
    class M
      class << self
        def singleton_method?
          true
        end
        alias alias_singleton_method? singleton_method?
      end

      def initialize(a)
        @a = a
      end

      def a_ten
        @a * 10
      end

      def b_ten(b)
        b * 10
      end

      alias c_ten a_ten

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

      def multi_types(key)
        {
          0 => 0,
          1 => '1',
          '2' => '2',
          '3' => 3,
        }[key]
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

    class CustomClassInspect
      def self.inspect = "it's customized"
      def self.a = 1
    end

    module CallsOtherModule
      def self.calls_other_module_method
        "#{M.new(0).a_ten}"
      end
    end
  }

  def test_method(t)
    store = Orthoses::Trace::Method.new(->{
      LOADER_METHOD.call

      m = M.new(100)
      m.a_ten
      m.b_ten(20)
      m.c_ten
      m.call_priv(true)
      m.call_priv(false)
      m.dele(true)

      m.simple_raise rescue nil
      m.if_raise(false)
      m.if_raise(true) rescue nil

      M.singleton_method?
      M.alias_singleton_method?

      Orthoses::Utils.new_store
    }, patterns: ['TraceMethodTest::M']).call

    actual = store.map { |n, c| c.to_rbs }.join("\n")
    expect = <<~RBS
      class TraceMethodTest::M
        private def initialize: (Integer a) -> void
        def a_ten: () -> Integer
        def b_ten: (Integer b) -> Integer
        private def priv: (bool bool) -> (Integer | Symbol)
        def call_priv: (bool c) -> (Integer | Symbol)
        def dele: (*Array[bool] a, **Hash[untyped, untyped]) -> Integer
        def if_raise: (bool a) -> String
        def self.singleton_method?: () -> bool
        alias c_ten a_ten
        alias self.alias_singleton_method? self.singleton_method?
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  if Class.instance_methods.include?(:attached_object)
    def test_custom_inspect(t)
      store = Orthoses::Trace::Method.new(->{
        LOADER_METHOD.call

        CustomClassInspect.a

        Orthoses::Utils.new_store
      }, patterns: ['TraceMethodTest::CustomClassInspect']).call

      actual = store.map { |n, c| c.to_rbs }.join("\n")
      expect = <<~RBS
        class TraceMethodTest::CustomClassInspect
          def self.a: () -> Integer
        end
      RBS
      unless expect == actual
        t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
      end
    end
  end

  def test_trace_point_filter(t)
    trace_point_filter = ->(name) { name == "TraceMethodTest::M" }
    store = Orthoses::Trace::Method.new(-> {
      LOADER_METHOD.call

      m = M.new(100)
      m.a_ten
      m.call_priv(true)

      Orthoses::Utils.new_store
    }, patterns: %w[*], trace_point_filter: trace_point_filter).call

    actual = store.map { |n, c| c.to_rbs }.join("\n")
    expect = <<~RBS
      class TraceMethodTest::M
        private def initialize: (Integer a) -> void
        def a_ten: () -> Integer
        private def priv: (bool bool) -> Integer
        def call_priv: (bool c) -> Integer
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  def test_raise_first(t)
    Orthoses::Trace::Method.new(->{
      raise rescue nil
      Orthoses::Utils.new_store
    }, patterns: ['TraceMethodTest']).call
  end

  def test_union_sort(t)
    store1 = Orthoses::Trace::Method.new(-> {
      LOADER_METHOD.call
      m = M.new(100)
      m.multi_types 0
      m.multi_types 1
      m.multi_types '2'
      m.multi_types '3'

      Orthoses::Utils.new_store
    }, patterns: ['TraceMethodTest::M']).call

    store2 = Orthoses::Trace::Method.new(-> {
      LOADER_METHOD.call
      m = M.new(100)
      m.multi_types '3'
      m.multi_types '2'
      m.multi_types 1
      m.multi_types 0

      Orthoses::Utils.new_store
    }, patterns: ['TraceMethodTest::M']).call

    expect = store1.map { _2.to_rbs }.join("\n")
    actual = store2.map { _2.to_rbs }.join("\n")
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  def test_without_union_sort(t)
    store = Orthoses::Trace::Method.new(-> {
      LOADER_METHOD.call
      m = M.new(100)
                        # The order of the union types will be the following
      m.multi_types '3' # (String) -> Integer
      m.multi_types '2' # (String) -> String
      m.multi_types 1   # (Integer) -> String
      m.multi_types 0   # (Integer) -> Integer

      Orthoses::Utils.new_store
    }, patterns: ['TraceMethodTest::M'], sort_union_types: false).call

    actual = store.map { _2.to_rbs }.join("\n")
    expect = <<~RBS
      class TraceMethodTest::M
        private def initialize: (Integer a) -> void
        def multi_types: (String key) -> (Integer | String)
                       | (Integer key) -> (String | Integer)
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end

  def test_filtering(t)
    store = Orthoses::Trace::Method.new(->{
      LOADER_METHOD.call

      CallsOtherModule.calls_other_module_method

      Orthoses::Utils.new_store
    }, patterns: ['TraceMethodTest::CallsOtherModule']).call

    actual = store.map { |n, c| c.to_rbs }.join("\n")
    expect = <<~RBS
      module TraceMethodTest::CallsOtherModule
        def self.calls_other_module_method: () -> String
      end
    RBS
    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
