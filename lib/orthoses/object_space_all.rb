module Orthoses
  class ObjectSpaceAll
    def initialize(loader, if: nil)
      @loader = loader
      @if = binding.local_variable_get(:if)
    end

    def call(env)
      store = @loader.call(env)

      modules_after = ObjectSpace.each_object(Module).to_a
      modules_after.each do |mod|
        next if Util.module_name(mod).nil?
        next unless @if.nil? || @if.call(mod)

        store[Util.module_name(mod)] ||= []
      end

      store
    end
  end
end
