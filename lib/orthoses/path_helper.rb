# frozen_string_literal: true

# Helper for find best version dir.
#   Orthoses::PathHelper.best_version_paths(
#     ::ActiveSupport::VERSION::STRING,
#     "known_sig/activesupport")
module Orthoses
  class PathHelper
    class << self
      def best_version_paths(current, base_dir)
        new(current, base_dir).best_version_paths
      end
    end

    def initialize(current, base_dir)
      @current = current
      @base_dir = base_dir
    end

    def best_version_paths
      best_version = find_best_version
      Dir.glob("#{@base_dir}/#{best_version}/**/*.rbs")
    end

    def find_best_version
      current_v = Gem::Version.new(@current)
      versions = version_dir
      versions.reverse.bsearch { |v| v <= current_v } || versions.first
    end

    def version_dir
      Dir.glob("#{@base_dir}/*")
        .map(&File.method(:basename))
        .map(&Gem::Version.method(:new))
        .sort
    end
  end
end
