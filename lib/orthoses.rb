# frozen_string_literal: true

require 'rbs'
require 'pathname'
require 'stringio'

require 'orthoses/utils'

module Orthoses
  autoload :Attribute, 'orthoses/attribute'
  autoload :Builder, 'orthoses/builder'
  autoload :CallTracer, 'orthoses/call_tracer'
  autoload :Constant, 'orthoses/constant'
  autoload :Content, 'orthoses/content'
  autoload :CreateFileByName, 'orthoses/create_file_by_name'
  autoload :DelegateClass, 'orthoses/delegate_class'
  autoload :Descendants, 'orthoses/descendants'
  autoload :ExcludeRBS, 'orthoses/exclude_rbs'
  autoload :Filter, 'orthoses/filter'
  autoload :Mixin, 'orthoses/mixin'
  autoload :LazyTracePoint, 'orthoses/lazy_trace_point'
  autoload :LoadRBS, 'orthoses/load_rbs'
  autoload :MissingName, 'orthoses/missing_name'
  autoload :ObjectSpaceAll, 'orthoses/object_space_all'
  autoload :Outputable, 'orthoses/outputable'
  autoload :PathHelper, 'orthoses/path_helper'
  autoload :PP, 'orthoses/pp'
  autoload :RBSPrototypeRB, 'orthoses/rbs_prototype_rb'
  autoload :RBSPrototypeRuntime, 'orthoses/rbs_prototype_runtime'
  autoload :Sort, 'orthoses/sort'
  autoload :Store, 'orthoses/store'
  autoload :Tap, 'orthoses/tap'
  autoload :Trace, 'orthoses/trace'
  autoload :Autoload, 'orthoses/autoload'
  autoload :VERSION, 'orthoses/version'
  autoload :Walk, 'orthoses/walk'
  autoload :Writer, 'orthoses/writer'

  METHOD_METHOD = ::Kernel.instance_method(:method)
  INSTANCE_METHOD_METHOD = ::Module.instance_method(:instance_method)

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
  self.logger = ::Logger.new($stdout, level: :info)
end
