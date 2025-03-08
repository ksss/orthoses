# frozen_string_literal: true

require 'test_helper'

module LazyTracePointTest
  LOADER1 = ->{
    class Bar
      def bar(name)
      end
    end
  }
  def test_lazy_instance_method_trace(t)
    called = []
    tp = Orthoses::LazyTracePoint.new(:call) do |tp|
      called << tp
    end
    tp.enable(target: 'LazyTracePointTest::Bar#bar') do
      called << self
      if Object.const_defined?('LazyTracePointTest::Bar')
        t.error("expect LazyTracePointTest::Bar is not defined here")
      end
      LOADER1.call
      Bar.new.bar(:bar)
    end
    Bar.new.bar(:bar) # to check out of scope

    unless !tp.enabled?
      t.fatal("expect to be disabled")
    end
    unless called.length == 2
      t.error("expect to call block twice. But #{called.length}")
    end
    unless called[0] == LazyTracePointTest
      t.error("expect LazyTracePointTest, but got #{called[0].inspect}")
    end
    unless called[1].instance_of?(Orthoses::LazyTracePoint)
      t.error("expect Orthoses::LazyTracePoint instance, but got #{called[1].inspect}")
    end

    # loaded
    called = []
    tp = Orthoses::LazyTracePoint.new(:call) do |tp|
      called << tp
    end
    tp.enable(target: 'LazyTracePointTest::Bar#bar') do
      called << self
      Bar.new.bar(:bar)
    end
    Bar.new.bar(:bar) # to check out of scope

    unless !tp.enabled?
      t.fatal("expect to be disabled")
    end
    unless called.length == 2
      t.fatal("expect to call block")
    end
    unless called[0] == LazyTracePointTest
      t.error("expect LazyTracePointTest, but got #{called[0].inspect}")
    end
    unless called[1].instance_of?(Orthoses::LazyTracePoint)
      t.error("expect Orthoses::LazyTracePoint instance, but got #{called[1].inspect}")
    end
  end

  LOADER2 = ->{
    class Baz
      def self.baz(name)
      end
    end
  }
  def test_lazy_singleton_method_trace(t)
    called = []
    tp = Orthoses::LazyTracePoint.new(:call) do |tp|
      called << tp
    end
    tp.enable(target: 'LazyTracePointTest::Baz.baz') do
      called << self
      if Object.const_defined?('LazyTracePointTest::Baz')
        t.error("expect LazyTracePointTest::Baz is not defined here")
      end
      LOADER2.call
      Baz.baz(:baz)
    end
    Baz.baz(:baz) # to check out of scope

    unless !tp.enabled?
      t.fatal("expect to be disabled")
    end
    unless called.length == 2
      t.fatal("expect to call block")
    end
    unless called[0] == LazyTracePointTest
      t.error("expect LazyTracePointTest, but got #{called[0].inspect}")
    end
    unless called[1].instance_of?(Orthoses::LazyTracePoint)
      t.error("expect Orthoses::LazyTracePoint instance, but got #{called[1].inspect}")
    end

    # loaded
    called = []
    tp = Orthoses::LazyTracePoint.new(:call) do |tp|
      called << tp
    end
    tp.enable(target: 'LazyTracePointTest::Baz.baz') do
      called << self
      Baz.baz(:baz)
    end
    Baz.baz(:baz) # to check out of scope

    unless !tp.enabled?
      t.fatal("expect to be disabled")
    end
    unless called.length == 2
      t.fatal("expect to call block")
    end
    unless called[0] == LazyTracePointTest
      t.error("expect LazyTracePointTest, but got #{called[0].inspect}")
    end
    unless called[1].instance_of?(Orthoses::LazyTracePoint)
      t.error("expect Orthoses::LazyTracePoint instance, but got #{called[1].inspect}")
    end
  end

  # https://bugs.ruby-lang.org/issues/19833
  def test_19833(t)
    unless BasicObject.superclass.nil?
      t.error("Should support https://bugs.ruby-lang.org/issues/19833")
    end
  end
end
