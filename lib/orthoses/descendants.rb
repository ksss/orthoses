# frozen_string_literal: true

module Orthoses
  # use Orthoses::Descendants, of: 'ApplicationJob'
  class Descendants
    def initialize(loader, of:)
      @loader = loader
      @of = of
    end

    def call
      @loader.call.tap do |store|
        super_class =
          case @of
          when String
            Object.const_get(@of)
          else
            @of
          end

        unless super_class.kind_of?(Class)
          raise "`of` option should be String or Class"
        end

        descendants_of(super_class).each do |descendant|
          base_name = Orthoses::Utils.module_name(descendant) or next
          store[base_name]
        end
      end
    end

    private

    def descendants_of(klass)
      ObjectSpace.each_object(klass.singleton_class).reject do |k|
        k.singleton_class? || k == klass
      end
    end
  end
end
