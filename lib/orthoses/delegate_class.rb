# frozen_string_literal: true

module Orthoses
  class DelegateClass
    module Hook
      def inherited(subclass)
        super
      end
    end

    def initialize(loader)
      @loader = loader
    end

    def call
      require 'delegate'
      ::Class.prepend(Hook)

      inherited = CallTracer.new

      delegate_class_super_map = {}
      delegate_class_tracer = TracePoint.new(:return) do |tp|
        return_value = tp.return_value
        superclass = tp.binding.local_variable_get(:superclass)
        delegate_class_super_map[return_value] = superclass
      end

      store = delegate_class_tracer.enable(target: method(:DelegateClass)) do
        inherited.trace(Hook.instance_method(:inherited)) do
          @loader.call
        end
      end

      inherited.captures.each do |capture|
        superclass = capture.method.receiver
        if delegate_to_class = delegate_class_super_map[superclass]
          subclass = capture.argument[:subclass]
          subclass_name = Utils.module_name(subclass)
          next unless subclass_name

          delegate_to_class_name = Utils.module_name(delegate_to_class)
          next unless delegate_to_class_name

          header = "class #{subclass_name} < ::#{delegate_to_class_name}#{temporary_type_params(delegate_to_class_name)}"
          store[subclass_name].header = header
        end
      end

      store
    end

    def temporary_type_params(name)
      Utils.known_type_params(name)&.then do |params|
        if params.empty?
          nil
        else
          "[#{params.map { :untyped }.join(', ')}]"
        end
      end
    end
  end
end
