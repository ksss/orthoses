# frozen_string_literal: true

module Orthoses
  # LazyTracePoint.new(:call) do |tp|
  #   ...
  # end.enable(target: 'Class#class_attribute') do
  #   require 'active_support/core_ext/class/attribute'
  #   ...
  # end
  class LazyTracePoint
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

    def initialize(*events, &block)
      @mod_name = nil
      @instance_method_id = nil
      @singleton_method_id = nil
      @target_tp = TracePoint.new(*events, &block)
    end

    def enable(target:, &block)
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
      # load try
      target = Object.const_get(@mod_name).instance_method(@instance_method_id)
      @target_tp.enable(target: target, &block)
    rescue NameError
      TracePoint.new(:call) do |tp|
        id = tp.binding.local_variable_get(:id)
        next unless id == @instance_method_id

        mod_name = Utils.module_name(tp.self)

        next unless mod_name
        next unless mod_name == @mod_name

        @target_tp.enable(target: INSTANCE_METHOD_METHOD.bind(tp.self).call(id))
        tp.disable
      end.enable(target: ::Module.instance_method(:method_added), &block)
    ensure
      @target_tp.disable
    end

    def trace_singleton_method(&block)
      # load try
      target = Object.const_get(@mod_name).method(@singleton_method_id)
      @target_tp.enable(target: target, &block)
    rescue NameError
      TracePoint.new(:call) do |tp|
        id = tp.binding.local_variable_get(:id)
        next unless id == @singleton_method_id

        mod_name = Utils.module_name(tp.self)

        next unless mod_name
        next unless mod_name == @mod_name

        @target_tp.enable(target: METHOD_METHOD.bind(tp.self).call(id))
        tp.disable
      end.enable(target: ::BasicObject.instance_method(:singleton_method_added), &block)
    ensure
      @target_tp.disable
    end
  end
end
