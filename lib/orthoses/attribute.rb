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

      attr.result.each do |method, argument|
        receiver_name = Utils.module_name(method.receiver) or next
        content = store[receiver_name]
        if argument[:names][1].equal?(true)
          content << "attr_accessor #{argument[:names][0]}: untyped"
        elsif argument[:names][1].equal?(false)
          content << "attr_reader #{argument[:names][0]}: untyped"
        else
          argument[:names].each do |name|
            content << "attr_reader #{name}: untyped"
          end
        end
      end

      attr_accessor.result.each do |method, argument|
        receiver_name = Utils.module_name(method.receiver) or next
        content = store[receiver_name]
        argument[:names].each do |name|
          content << "attr_accessor #{name}: untyped"
        end
      end

      attr_reader.result.each do |method, argument|
        receiver_name = Utils.module_name(method.receiver) or next
        content = store[receiver_name]
        argument[:names].each do |name|
          content << "attr_reader #{name}: untyped"
        end
      end

      attr_writer.result.each do |method, argument|
        receiver_name = Utils.module_name(method.receiver) or next
        content = store[receiver_name]
        argument[:names].each do |name|
          content << "attr_writer #{name}: untyped"
        end
      end

      store
    end
  end
end
