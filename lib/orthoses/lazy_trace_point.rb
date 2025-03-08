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
    METHOD_METHOD = ::Kernel.instance_method(:method)
    INSTANCE_METHOD_METHOD = ::Module.instance_method(:instance_method)
    UNBOUND_NAME_METHOD = ::Module.instance_method(:name)
    METHOD_ADDED_HOOKS = {}
    SINGLETON_METHOD_ADDED_HOOKS = {}

    # for TracePoint target
    module MethodAddedHook
      def method_added(id)
        begin
          if h = METHOD_ADDED_HOOKS[id]
            if mod_name = UNBOUND_NAME_METHOD.bind(self).call
              h[mod_name]&.call(self, id)
            end
          end
        rescue TypeError
        end
        super
      end
    end
    ::Module.prepend MethodAddedHook

    class ::BasicObject
      undef singleton_method_added
      def singleton_method_added(id)
        begin
          if h = SINGLETON_METHOD_ADDED_HOOKS[id]
            if mod_name = UNBOUND_NAME_METHOD.bind(self).call
              h[mod_name]&.call(self, id)
            end
          end
        rescue TypeError
        end
      end
    end

    def enable(target: nil, &block)
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
      target = Object.const_get(@mod_name).instance_method(@instance_method_id)
      enable(target: target, &block)
    rescue NameError
      (METHOD_ADDED_HOOKS[@instance_method_id] ||= {})[@mod_name] = ->(const, id) {
        enable(target: INSTANCE_METHOD_METHOD.bind(const).call(id))
      }
      block&.call
    ensure
      disable
    end

    def trace_singleton_method(&block)
      target = Object.const_get(@mod_name).method(@singleton_method_id)
      enable(target: target, &block)
    rescue NameError
      (SINGLETON_METHOD_ADDED_HOOKS[@singleton_method_id] ||= {})[@mod_name] = ->(const, id) {
        enable(target: METHOD_METHOD.bind(const).call(id))
      }
      block&.call
    ensure
      disable
    end
  end
end
