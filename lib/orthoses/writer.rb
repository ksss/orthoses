module Orthoses
  class Writer
    prepend Outputable

    def initialize(loader, io:)
      @loader = loader
      @io = io
    end

    def call
      @loader.call.tap do |store|
        store.each do |name, content|
          @io.write content.to_rbs
        end
      end
    end
  end
end
