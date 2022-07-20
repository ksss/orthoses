# frozen_string_literal: true

module Orthoses
  module Outputable
    # AvoidRecursiveAncestorError is an internal middleware
    # It's using on orthoses/outputable.rb
    class AvoidRecursiveAncestorError
      def initialize(loader)
        @loader = loader
      end

      def call
        @loader.call.tap do |store|
          object_mixins = {}
          collect_mixin_recursive(store, "Object", object_mixins)

          object_mixins.each_key do |object_mixin|
            store[object_mixin].header = "module #{object_mixin} : BasicObject"
          end
        end
      end

      private

      def collect_mixin_recursive(store, name, mixins)
        store[name].to_decl.members.each do |member|
          case member
          when RBS::AST::Members::Mixin
            member_name = member.name.relative!.to_s
            mixins[member_name] = true
            collect_mixin_recursive(store, member_name, mixins)
          end
        end
      end
    end
  end
end
