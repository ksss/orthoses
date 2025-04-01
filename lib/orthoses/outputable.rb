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
    autoload :ResolveTypeNames, 'orthoses/outputable/resolve_type_names'

    def initialize(loader, resolve_type_names: false, **)
      @resolve_type_names = resolve_type_names
      super(loader, **)
    end

    def call
      @loader = AvoidRecursiveAncestorError.new(@loader)
      @loader = ConstantizableFilter.new(@loader)
      @loader = UniqContentBody.new(@loader)
      @loader = ResolveTypeNames.new(@loader) if @resolve_type_names
      super
    end
  end
end
