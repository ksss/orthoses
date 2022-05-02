# frozen_string_literal: true

module Orthoses
  class Walk
    def initialize(loader, root:)
      @loader = loader
      @root = root
    end

    def call(env)
      @loader.call(env).tap do |store|
        root = Object.const_get(@root) if @root.instance_of?(String)
        store[root]
        Orthoses::Util.each_const_recursive(root) do |current, const, val|
          store[val] if val.kind_of?(Module)
        end
      end
    end
  end
end
