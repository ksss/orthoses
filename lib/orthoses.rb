# frozen_string_literal: true

require 'rbs'
require 'pathname'

require_relative 'orthoses/builder'
require_relative 'orthoses/call_tracer'
require_relative 'orthoses/constant'
require_relative 'orthoses/create_file_by_name'
require_relative 'orthoses/rbs_store'
require_relative 'orthoses/filter'
require_relative 'orthoses/include_extend_prepend'
require_relative 'orthoses/known_sig'
require_relative 'orthoses/logger'
require_relative 'orthoses/object_space_all'
require_relative 'orthoses/pp'
require_relative 'orthoses/store'
require_relative 'orthoses/util'
require_relative 'orthoses/version'
require_relative 'orthoses/walk'

module Orthoses
  class ConstLoadError < StandardError
    attr_reader :root
    attr_reader :const
    attr_reader :error
    def initialize(root:, const:, error:)
      @root = root
      @const = const
      @error = error
    end

    def message
      "root=#{root}, const=#{const}, error=#{error.inspect}"
    end
  end

  class NameSpaceError < StandardError
  end

  class << self
    attr_accessor :logger
  end
  self.logger = ::Logger.new($stdout)
end
