module Orthoses
  class AvoidRecursiveAncestorError
    def initialize(loader)
      @loader = loader
    end

    def call
      @loader.call.tap do |store|
        object_mixins = {}
        set_object_mixins_recursive(store, "Object", object_mixins)

        object_mixins.each_key do |object_mixin|
          store[object_mixin].header = "module #{object_mixin} : BasicObject"
        end
      end
    end

    def set_object_mixins_recursive(store, name, object_mixins)
      store[name].to_decl.members.each do |member|
        case member
        when RBS::AST::Members::Mixin
          member_name = member.name.relative!.to_s
          object_mixins[member_name] = true
          set_object_mixins_recursive(store, member_name, object_mixins)
        end
      end
    end
  end
end
