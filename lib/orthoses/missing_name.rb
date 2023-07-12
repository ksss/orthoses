# frozen_string_literal: true

module Orthoses
  class MissingName
    def initialize(loader)
      @loader = loader
    end

    def call
      @loader.call.tap do |store|
        MissingClass.new(store).call
        MissingModule.new(store).call
      end
    end

    private

    class MissingClass
      def initialize(store)
        @store = store
      end

      def call
        @store.values.each do |content|
          recur(content)
        end
      end

      private

      def recur(content)
        content.auto_header
        if content.header && content.header.include?("<")
          _, superclass = content.header.split(/\s*<\s*/, 2)
          superclass.sub!(/\[.*/, "")
          new_name = TypeName(superclass).relative!.to_s
          recur(@store[new_name])
        end
      end
    end

    class MissingModule
      def initialize(store)
        @store = store
      end

      def call
        missings = []
        @store.keys.each do |key_name|
          missings.concat split_name(key_name)
        end
        missings.uniq!
        missings.each do |missing|
          @store[missing].header = "module #{missing}"
        end
      end

      private

      def split_name(key_name)
        ret = []

        type_name = TypeName(key_name).relative!
        if !Utils.rbs_defined_class?(type_name.to_s) && !@store.has_key?(type_name.to_s)
          ret << type_name.to_s
        end

        path = type_name.namespace.path
        path.each_with_index do |sym, index|
          name = path[0, index + 1].join("::")
          next if name.empty?
          if !Utils.rbs_defined_class?(name) && !@store.has_key?(name)
            ret << name
          end
        end

        ret
      end
    end
  end
end
