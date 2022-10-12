# frozen_string_literal: true

require 'orthoses/outputable/avoid_recursive_ancestor_error'
require 'orthoses/outputable/constantizable_filter'
require 'orthoses/outputable/uniq_content_body'

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
      @loader = UniqContentBody.new(@loader)
      @loader = ConstantizableFilter.new(@loader)
      super
    end
  end
end
