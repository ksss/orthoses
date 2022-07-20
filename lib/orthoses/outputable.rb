# frozen_string_literal: true

require 'orthoses/outputable/avoid_recursive_ancestor_error'

module Orthoses
  # Module for output middleware.
  # Call internal some middleware on output phase.
  #   class Sample
  #     prepend Outputable
  #
  #     def initialize(loader)
  #       ...
  #     def call
  #       ...
  module Outputable
    def call
      @loader = AvoidRecursiveAncestorError.new(@loader)
      super
    end
  end
end
