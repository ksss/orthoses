# frozen_string_literal: true

module Orthoses
  # TracePoint wrapper that allows setting hooks
  # even if the target is undefined
  #   LazyTracePoint.new(:call) do |tp|
  #     ...
  #   end.enable(target: 'Class#class_attribute') do
  #     require 'active_support/core_ext/class/attribute'
  #     ...
  #   end
  class LazyTracePoint < TracePoint
    # for TracePoint target
    ::Module.prepend(Module.new{
      def method_added(id)
        super
      end
    })
    ::BasicObject.prepend(Module.new{
      def singleton_method_added(id)
        super
      end
    })

    METHOD_METHOD = ::Kernel.instance_method(:method)
    INSTANCE_METHOD_METHOD = ::Module.instance_method(:instance_method)
    UNBOUND_NAME_METHOD = ::Module.instance_method(:name)
    METHOD_ADDED_METHOD = ::Module.instance_method(:method_added)
    SINGLETON_METHOD_ADDED_METHOD = ::BasicObject.instance_method(:singleton_method_added)

    def initialize(*events, &block)
      @mod_name = nil
      @instance_method_id = nil
      @singleton_method_id = nil
      super
    end

    def enable(target: nil, target_line: nil, target_thread: nil, &block)
      return super unless target.kind_of?(String)

      case
      when target.include?('#')
        @mod_name, instance_method_id = target.split('#', 2)
        @instance_method_id = instance_method_id.to_sym
        @singleton_method_id = nil

        trace_instance_method(&block)
      when target.include?('.')
        @mod_name, singleton_method_id = target.split('.', 2)
        @singleton_method_id = singleton_method_id.to_sym
        @instance_method_id = nil

        trace_singleton_method(&block)
      else
        raise ArgumentError, "argument shuold be 'Foo#foo' or 'Foo.foo' format"
      end
    end

    private

    def trace_instance_method(&block)
      # try to load
      target = Object.const_get(@mod_name).instance_method(@instance_method_id)
      enable(target: target, &block)
    rescue NameError
      TracePoint.new(:call) do |tp|
        id = tp.binding.local_variable_get(:id)
        next unless id == @instance_method_id

        mod_name = UNBOUND_NAME_METHOD.bind(tp.self).call

        next unless mod_name
        next unless mod_name == @mod_name

        enable(target: INSTANCE_METHOD_METHOD.bind(tp.self).call(id))
        tp.disable
      end.enable(target: METHOD_ADDED_METHOD, &block)
    ensure
      disable
    end

    def trace_singleton_method(&block)
      # try to load
      target = Object.const_get(@mod_name).method(@singleton_method_id)
      enable(target: target, &block)
    rescue NameError
      TracePoint.new(:call) do |tp|
        id = tp.binding.local_variable_get(:id)
        next unless id == @singleton_method_id

        mod_name = UNBOUND_NAME_METHOD.bind(tp.self).call

        next unless mod_name
        next unless mod_name == @mod_name

        enable(target: METHOD_METHOD.bind(tp.self).call(id))
        tp.disable
      end.enable(target: SINGLETON_METHOD_ADDED_METHOD, &block)
    ensure
      disable
    end
  end
end
