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
      store.each do |name, bodies|
        next if name == "Module"
        next if name.start_with?('#<')
        next if Util::VIRTUAL_NAMESPACE.match?(name)
        next if !Util.check_const_getable(name) { |e| env[:logger]&.info(e) }

        base = Object.const_get(name)
        Orthoses::Util.each_const_recursive(base, on_error: @on_error) do |current, const, val|
          next if current.singleton_class?
          next if current.name.nil?
          next if val.kind_of?(Module)
          next unless @if.nil? || @if.call(current, const, val)

          module_name = Util.module_name(current)
          next if cache[[module_name, const]]

          rbs = Orthoses::Util.object_to_rbs(val)
          next unless rbs

          store[module_name] << "#{const}: #{rbs}"

          cache[[module_name, const]] = true
        end
      end
      store
    end
  end
end
