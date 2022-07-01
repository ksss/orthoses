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
      t.error("cannot capture method")
    end
    c.captures.each do |capture|
      unless capture.instance_of?(Orthoses::CallTracer::Capture)
        t.error("break instance #{capture}")
      end
    end
  end
end
