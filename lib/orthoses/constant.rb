# frozen_string_literal: true

module Orthoses
  class Constant
    def initialize(loader, strict: false, if: nil, on_error: nil)
      @loader = loader
      @strict = strict
      @if = binding.local_variable_get(:if)
      @on_error = on_error
    end

    def call
      cache = {}
      @loader.call.tap do |store|
        will_add_key_and_content = []
        store.each do |name, _|
          next if name.start_with?('#<')

          begin
            base = Object.const_get(name)
          rescue NameError, ArgumentError, LoadError
            # i18n/tests raise ArgumentError
            next
          end
          next unless base.kind_of?(Module)
          Orthoses::Utils.each_const_recursive(base, on_error: @on_error) do |current, const, val|
            next if current.singleton_class?
            next if Utils.module_name(current).nil?
            next if cache[[current, const]]
            cache[[current, const]] = true

            if val.kind_of?(Module)
              next unless @if.nil? || @if.call(current, const, val, nil)
              will_add_key_and_content << [Utils.module_name(val), nil]
              next
            end

            rbs = Orthoses::Utils.object_to_rbs(val, strict: @strict)
            next unless rbs
            next unless @if.nil? || @if.call(current, const, val, rbs)

            will_add_key_and_content << [Utils.module_name(current), "#{const}: #{rbs}"]
          end
        end

        will_add_key_and_content.each do |name, line|
          next unless name
          content = store[name]
          next unless line
          content << line
        end
      end
    end
  end
end
