require 'test_helper'

module AvoidRecursiveAncestorErrorTest
  def test_avoid_recursive_ancestor_error(t)
    store = Orthoses::Outputable::AvoidRecursiveAncestorError.new(->(){
      Orthoses::Utils.new_store.tap do |store|
        store["Nested"].header = "module Nested"
        store["Imod"].header = "module Imod"
        store["Emod"].header = "module Emod"
        store["Pmod"].header = "module Pmod"
        store["Nested"]
        store["Imod"] << "include Nested"
        store["Emod"]
        store["Pmod"]
        store["Object"] << "include Imod"
        store["Object"] << "extend Emod"
        store["Object"] << "prepend Pmod"
      end
    }).call

    %w[Nested Imod Emod Pmod].each do |mod|
      unless store[mod].to_rbs.include?(" : BasicObject")
        t.error("expect #{mod} with self_type `BasicObject` but got #{store[mod].header}")
      end
    end
  end
end
