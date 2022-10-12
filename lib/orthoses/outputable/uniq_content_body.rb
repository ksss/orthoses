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
            content.uniq!
          end
        end
      end
    end
  end
end
