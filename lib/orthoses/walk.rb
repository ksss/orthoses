# frozen_string_literal: true

module Orthoses
  class Walk
    def initialize(loader, root:)
      @loader = loader
      @root = root
    end

    def call
      @loader.call.tap do |store|
        root = Object.const_get(@root) if @root.instance_of?(String)
        Utils.module_name(root)&.then { |root_name| store[root_name] }
        Orthoses::Utils.each_const_recursive(root) do |current, const, val|
          if val.kind_of?(Module)
            Utils.module_name(val)&.then do |val_name|
              Orthoses.logger.debug("Add [#{val_name}] on #{__FILE__}:#{__LINE__}")
              store[val_name]
            end
          end
        end
      end
    end
  end
end
