# frozen_string_literal: true

begin
  require 'test_helper'
rescue LoadError
end

module CallTracerTest
  class Foo
    def method
    end
  end

  def test_trace_with_method_method(t)
    c = Orthoses::CallTracer.new
    c.trace(Foo.instance_method(:method)) do
      Foo.new.method
    end

    unless c.captures.length == 1
      t.fatal("cannot capture method")
    end
    c.captures.each do |capture|
      unless capture.instance_of?(Orthoses::CallTracer::Capture)
        t.error("break instance #{capture}")
      end
    end
  end

  class UnnamedParameters
    def receive(a, b = nil, c:)
    end

    def captured(a, ...)
      receive(a, ...)
    end
  end

  def test_unnamed_parameters(t)
    c = Orthoses::CallTracer.new
    c.trace(UnnamedParameters.instance_method(:captured)) do
      UnnamedParameters.new.captured(:a, 'b', c: 'ccc') {}
    end
    c.captures.each do |capture|
      unless capture.argument[:a] == :a
        t.error("could not capture named argument")
      end
      unless capture.argument[:*] == ['b']
        t.error("could not capture `*` argument")
      end
      unless capture.argument[:**] == {c: 'ccc'}
        t.error("could not capture `*` argument")
      end
      unless capture.argument[:&].kind_of?(Proc)
        t.error("could not capture `&` argument")
      end
      unless capture.argument[:"..."][0] == ['b']
        t.error("could not capture `...` argument")
      end
      unless capture.argument[:"..."][1] == {c: 'ccc'}
        t.error("could not capture `...` argument")
      end
      unless capture.argument[:"..."][2].kind_of?(Proc)
        t.error("could not capture `...` argument")
      end
    end
  end
end
