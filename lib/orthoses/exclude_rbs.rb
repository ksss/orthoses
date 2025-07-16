# frozen_string_literal: true

module Orthoses
  # Exclude RBS from output.
  # @example
  #   use Orthoses::ExcludeRBS, paths: Dir['sig/hand-written/**/*.rbs']
  class ExcludeRBS
    def initialize(loader, paths: nil, rbs: nil)
      raise ArgumentError, ':paths or :rbs keyword is required' if paths.nil? && rbs.nil?

      @loader = loader
      @paths = paths
      @rbs = rbs
    end

    def call
      case
      when @paths
        @paths.each do |path|
          add_signature_to_known_env(File.read(path.to_s))
        end
      when @rbs
        add_signature_to_known_env(@rbs)
      else
        raise "bug"
      end

      rebuild_environment

      @loader.call
    end

    def add_signature_to_known_env(rbs)
      buffer, directives, decls = ::RBS::Parser.parse_signature(rbs)
      Utils.rbs_environment.add_signature(buffer: buffer, directives: directives, decls: decls)
    end

    def rebuild_environment
      old_env = Utils.rbs_environment
      new_env = old_env.resolve_type_names
      Utils.module_eval { @env_cache[[nil, true]] = new_env }
    end
  end
end
