# frozen_string_literal: true

module Orthoses
  module Outputable
    # Constantizable is an internal middleware
    # It's using on orthoses/outputable.rb
    class ConstantizableFilter
      def initialize(loader)
        @loader = loader
      end

      def call
        @loader.call.tap do |store|
          failures = []
          store.each do |name, content|
            next if content.header
            next if content.interface?

            begin
              Object.const_get(name)
            rescue NameError, LoadError => err
              Orthoses.logger.error(err.inspect)
              failures << name
              next
            end
          end
          failures.each { |name| store.delete(name) }
        end
      end
    end
  end
end
