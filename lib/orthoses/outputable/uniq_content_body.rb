# frozen_string_literal: true

module Orthoses
  module Outputable
    # UniqContentBody is an internal middleware
    # It's using on orthoses/outputable.rb
    class UniqContentBody
      def initialize(loader)
        @loader = loader
      end

      def call
        @loader.call.tap do |store|
          store.each do |name, content|
            begin
              content.uniq!
            rescue NameError, LoadError => err
              Orthoses.logger.error(err.inspect)
              next
            end
          end
        end
      end
    end
  end
end
