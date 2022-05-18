module AvoidRecursiveAncestorErrorTest
  def test_avoid_recursive_ancestor_error(t)
    store = Orthoses::AvoidRecursiveAncestorError.new(->(){
      Orthoses::Utils.new_store.tap do |store|
        store["Imod"]
        store["Emod"]
        store["Pmod"]
        store["Object"] << "include Imod"
        store["Object"] << "extend Emod"
        store["Object"] << "prepend Pmod"
      end
    }).call

    %w[Imod Emod Pmod].each do |mod|
      unless store[mod].to_rbs.include?(" : BasicObject")
        t.error("expect #{mod} with self_type `BasicObject` but got #{store[mod].header}")
      end
    end
  end
end
