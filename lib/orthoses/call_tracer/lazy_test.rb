# frozen_string_literal: true

require 'test_helper'

module CallTracerLazyTest
  LOADER1 = ->{
    class Bar
      def bar(name)
      end
    end
  }
  def test_lazy_instance_method_trace(t)
    lazy = Orthoses::CallTracer::Lazy.new
    if Object.const_defined?('CallTracerLazyTest::Bar')
      t.error("expect CallTracerLazyTest::Bar is not defined here")
    end
    lazy.trace('CallTracerLazyTest::Bar#bar') do
      LOADER1.call
      Bar.new.bar(:bar)
    end
    Bar.new.bar(:bar) # to check out of scope
    unless lazy.captures.length == 1
      t.fatal("unexpected captures")
    end
    unless lazy.captures.first.argument == {name: :bar}
      t.error("expect {name: :bar}, but got #{lazy.captures.first.argument.inspect}")
    end

    # loaded
    lazy = Orthoses::CallTracer::Lazy.new
    lazy.trace('CallTracerLazyTest::Bar#bar') do
      Bar.new.bar(:bar)
    end
    Bar.new.bar(:bar) # to check out of scope
    unless lazy.captures.length == 1
      t.fatal("unexpected captures")
    end
    unless lazy.captures.first.argument == {name: :bar}
      t.error("expect {name: :bar}, but got #{lazy.captures.first.argument.inspect}")
    end
  end

  LOADER2 = ->{
    class Baz
      def self.baz(name)
      end
    end
  }
  def test_lazy_singleton_method_trace(t)
    lazy = Orthoses::CallTracer::Lazy.new
    if Object.const_defined?('CallTracerLazyTest::Baz')
      t.fatal("expect CallTracerLazyTest::Baz is not defined here")
    end
    lazy.trace('CallTracerLazyTest::Baz.baz') do
      LOADER2.call
      Baz.baz(:baz)
    end
    Baz.baz(:baz) # to check out of scope
    unless lazy.captures.length == 1
      t.fatal("unexpected captures")
    end
    unless lazy.captures.first.argument == {name: :baz}
      t.error("expect {name: :baz}, but got #{lazy.captures.first.argument.inspect}")
    end

    # loaded
    lazy = Orthoses::CallTracer::Lazy.new
    lazy.trace('CallTracerLazyTest::Baz.baz') do
      Baz.baz(:baz)
    end
    Baz.baz(:baz) # to check out of scope
    unless lazy.captures.length == 1
      t.fatal("unexpected captures")
    end
    unless lazy.captures.first.argument == {name: :baz}
      t.error("expect {name: :baz}, but got #{lazy.captures.first.argument.inspect}")
    end
  end
end
