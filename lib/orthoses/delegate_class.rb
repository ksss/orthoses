# frozen_string_literal: true

module Orthoses
  class DelegateClass
    def initialize(loader)
      @loader = loader
    end

    def call
      require 'delegate'
      classes = []
      Class.class_eval do
        define_method(:inherited) do |subclass|
          classes << [subclass, self]
        end
      end
      delegate_class_super_map = {}
      delegate_class_tracer = TracePoint.new(:return) do |tp|
        return_value = tp.return_value
        superclass = tp.binding.local_variable_get(:superclass)
        delegate_class_super_map[return_value] = superclass
      end
      store = delegate_class_tracer.enable(target: method(:DelegateClass)) do
        @loader.call
      end
      classes.each do |subclass, superclass|
        if delegate_to_class = delegate_class_super_map[superclass]
          subclass_name = Utils.module_name(subclass)
          next unless subclass_name
          delegate_to_class_name = Utils.module_name(delegate_to_class)
          next unless delegate_to_class_name
          store[subclass_name].header = "class #{subclass_name} < #{delegate_to_class_name}"
        end
      end
      store
    end

    def from_DelegateClass?(klass)
      klass.name.nil? &&
        klass.superclass == Delegator &&
        klass.instance_methods.include?(:__setobj__) &&
        klass.instance_method(:__setobj__).source_location.first.end_with?("delegate.rb")
    end
  end
end
