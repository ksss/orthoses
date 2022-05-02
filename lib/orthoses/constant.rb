# frozen_string_literal: true

module Orthoses
  class Constant
    def initialize(loader, if: nil, on_error: nil)
      @loader = loader
      @if = binding.local_variable_get(:if)
      @on_error = on_error
    end

    def call(env)
      cache = {}
      store = @loader.call(env)
      store.each do |name, _|
        next if name.name == :Module
        next if name.name.start_with?('#<')

        begin
          base = Object.const_get(name.to_s)
        rescue NameError
          next
        end
        next unless base.kind_of?(Module)
        Orthoses::Util.each_const_recursive(base, on_error: @on_error) do |current, const, val|
          next if current.singleton_class?
          next if current.name.nil?
          next if val.kind_of?(Module)
          next if cache[[current, const]]

          rbs = Orthoses::Util.object_to_rbs(val)
          next unless rbs
          next unless @if.nil? || @if.call(current, const, val, rbs)

          store[current] << "::#{current}::#{const}: #{rbs}"

          cache[[current, const]] = true
        end
      end
      store
    end
  end
end
