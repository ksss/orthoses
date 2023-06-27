# frozen_string_literal: true

module Orthoses
  class MissingName
    def initialize(loader)
      @loader = loader
    end

    def call
      @loader.call.tap do |store|
        missing_class(store)
        missing_module(store)
      end
    end

    private

    def missing_module(store)
      missings = []
      store.keys.each do |key_name|
        missings.concat missing_names(store, key_name)
      end
      missings.uniq!
      missings.each do |missing|
        store[missing].header = "module #{missing}"
      end
    end

    def missing_class(store)
      missings = []
      store.each do |name, content|
        content.auto_header
        if content.header && content.header.include?("<")
          _, superclass = content.header.split(/\s*<\s*/, 2)
          superclass.sub!(/\[.*/, "")
          missings.concat missing_names(store, superclass)
        end
      end
      missings.uniq!
      missings.each do |missing|
        if !store.has_key?(missing)
          store[missing].auto_header
        end
      end
    end

    def missing_names(store, key_name)
      ret = []

      type_name = TypeName(key_name).relative!
      if !Utils.rbs_defined_class?(type_name.to_s) && !store.has_key?(type_name.to_s)
        ret << type_name.to_s
      end

      path = type_name.namespace.path
      path.each_with_index do |sym, index|
        name = path[0, index + 1].join("::")
        next if name.empty?
        if !Utils.rbs_defined_class?(name) && !store.has_key?(name)
          ret << name
        end
      end

      ret
    end
  end
end
