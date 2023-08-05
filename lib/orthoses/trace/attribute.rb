# frozen_string_literal: true

module Orthoses
  class Trace
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

      include Targetable

      def initialize(loader, patterns:)
        @loader = loader
        @patterns = patterns

        @captured_dict = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }
      end

      def call
        ::Module.prepend(Hook)
        store =
          build_trace_hook.enable(target: Hook.instance_method(:attr)) do
            build_trace_hook.enable(target: Hook.instance_method(:attr_accessor)) do
              build_trace_hook.enable(target: Hook.instance_method(:attr_reader)) do
                build_trace_hook.enable(target: Hook.instance_method(:attr_writer)) do
                  @loader.call
                end
              end
            end
          end

        @captured_dict.each do |mod_name, captures|
          captures.each do |(kind, prefix, name), types|
            injected = Utils::TypeList.new(types).inject
            store[mod_name] << "#{kind} #{prefix}#{name}: #{injected}"
          end
        end

        store
      end

      private

      def build_trace_hook
        TracePoint.new(:call) do |tp1|
          mod_name = Orthoses::Utils.module_name(tp1.self)
          if m = tp1.self.to_s.match(/#<Class:([\w:]+)>/)
            mod_name = m[1]
          end
          next unless mod_name
          next unless target?(mod_name)
          is_singleton = tp1.self.singleton_class?
          prefix = is_singleton ? "self." : ""
          kind = tp1.method_id

          tp1.binding.local_variable_get(:names).each do |name|
            attr_module = Module.new{
              if [:attr_accessor, :attr_reader, :attr].include?(kind)
                define_method(name) do
                  super()
                end
              end
              if [:attr_accessor, :attr_writer, :attr].include?(kind)
                define_method("#{name}=") do |object|
                  super(object)
                end
              end
            }

            tp1.self.prepend attr_module

            if [:attr_accessor, :attr_reader, :attr].include?(kind)
              TracePoint.new(:return) do |tp2|
                type = Utils.object_to_rbs(tp2.return_value)
                @captured_dict[mod_name][[kind, prefix, name]] << type
              end.enable(target: attr_module.instance_method(name))
            end
            if [:attr_accessor, :attr_writer, :attr].include?(kind)
              TracePoint.new(:call) do |tp2|
                type = Utils.object_to_rbs(tp2.binding.local_variable_get(:object))
                @captured_dict[mod_name][[kind, prefix, name]] << type
              end.enable(target: attr_module.instance_method("#{name}="))
            end
          end
        end
      end
    end
  end
end
