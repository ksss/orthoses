module Orthoses
  class AvoidRecursiveAncestorError
    def initialize(loader)
      @loader = loader
    end

    def call
      @loader.call.tap do |store|
        object_mixins = {}
        store["Object"].to_decl.members.each do |member|
          case member
          when RBS::AST::Members::Mixin
            object_mixins[member.name.relative!.to_s] = true
          end
        end
        object_mixins.each_key do |object_mixin|
          store[object_mixin].header = "module #{object_mixin} : BasicObject"
        end
      end
    end
  end
end
