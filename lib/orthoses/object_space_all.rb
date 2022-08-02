# frozen_string_literal: true

module Orthoses
  class ObjectSpaceAll
    def initialize(loader)
      @loader = loader
    end

    def call
      store = @loader.call

      after_modules = ObjectSpace.each_object(Module).to_a
      after_modules.each do |mod|
        mod_name = Utils.module_name(mod)
        next if mod_name.nil?

        store[mod_name]
      end

      store
    end
  end
end
