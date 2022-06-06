module Orthoses
  class Attribute
    module Hook
      def attr(*names)
        super
      end

      def attr_accessor(*names)
        super
      end

      def attr_reader(*names)
        super
      end

      def attr_writer(*names)
        super
      end
    end

    def initialize(loader)
      @loader = loader
    end

    def call
      Module.prepend(Hook)

      attr = CallTracer.new
      attr_accessor = CallTracer.new
      attr_reader = CallTracer.new
      attr_writer = CallTracer.new

      store = attr.trace(Hook.method(:attr)) do
        attr_accessor.trace(Hook.method(:attr_accessor)) do
          attr_reader.trace(Hook.method(:attr_reader)) do
            attr_writer.trace(Hook.method(:attr_writer)) do
              @loader.call
            end
          end
        end
      end

      store["Module"].body.delete("prepend Orthoses::Attribute::Hook")

      attr.captures.each do |capture|
        m = capture.method.receiver.to_s.match(/#<Class:([\w:]+)>/)
        if m && m[1]
          receiver_name = m[1]
          prefix = "self."
        else
          receiver_name = Utils.module_name(capture.method.receiver) or next
          prefix = nil
        end
        content = store[receiver_name]
        names = capture.argument[:names]
        if names[1].equal?(true)
          content << "attr_accessor #{prefix}#{names[0]}: untyped"
        elsif names[1].equal?(false)
          content << "attr_reader #{prefix}#{names[0]}: untyped"
        else
          names.each do |name|
            content << "attr_reader #{prefix}#{name}: untyped"
          end
        end
      end

      each_definition(attr_accessor) do |receiver_name, name|
        store[receiver_name] << "attr_accessor #{name}: untyped"
      end
      each_definition(attr_reader) do |receiver_name, name|
        store[receiver_name] << "attr_reader #{name}: untyped"
      end
      each_definition(attr_writer) do |receiver_name, name|
        store[receiver_name] << "attr_writer #{name}: untyped"
      end

      store
    end

    private

    def each_definition(call_tracer)
      call_tracer.captures.each do |capture|
        m = capture.method.receiver.to_s.match(/#<Class:([\w:]+)>/)
        names = capture.argument[:names]
        if m && m[1]
          receiver_name = m[1]
          names.each do |name|
            yield [receiver_name, "self.#{name}"]
          end
        else
          receiver_name = Utils.module_name(capture.method.receiver) or next
          names.each do |name|
            yield [receiver_name, name]
          end
        end
      end
    end
  end
end
