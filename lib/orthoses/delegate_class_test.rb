# frozen_string_literal: true

module DelegateClassTest
  def test_delegate_class(t)
    store = Orthoses::DelegateClass.new(->(){
      require 'tempfile'
      Orthoses::Utils.new_store
    }).call
    actual = store["Tempfile"].to_rbs
    expect = <<~RBS
      class Tempfile < File
      end
    RBS
  end
end
