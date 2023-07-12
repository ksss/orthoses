# frozen_string_literal: true

require 'orthoses/outputable'

module Orthoses
  class CreateFileByName
    prepend Outputable

    def initialize(loader, base_dir: nil, to: nil, header: nil, if: nil, depth: nil, rmtree: false)
      unless base_dir.nil?
        warn "[Orthoses::CreateFileByName] base_dir: option is deprecated. Please use to: option instead."
      end

      to = to || base_dir
      unless to
        raise ArgumentError, "should set to: option"
      end

      relative_path_from_pwd = Pathname(to).expand_path.relative_path_from(Pathname.pwd).to_s
      unless relative_path_from_pwd == "." || !relative_path_from_pwd.match?(%r{\A[/\.]})
        raise ArgumentError, "to=\"#{to}\" should be under current dir=\"#{Pathname.pwd}\"."
      end

      @loader = loader
      @to = to
      @header = header
      @depth = depth
      @rmtree = rmtree
      @if = binding.local_variable_get(:if)
    end

    using Utils::Underscore

    def call
      if @rmtree
        Orthoses.logger.debug("Remove dir #{@to} since `rmtree: true`")
        Pathname(@to).rmtree rescue nil
      end

      store = @loader.call

      store.select! do |name, content|
        @if.nil? || @if.call(name, content)
      end
      grouped = store.group_by do |name, _|
        splitted = name.to_s.split('::')
        (@depth ? splitted[0, @depth] : splitted).join('::')
      end

      grouped.each do |group_name, group|
        file_path = Pathname("#{@to}/#{group_name.split('::').map(&:underscore).join('/')}.rbs")
        file_path.dirname.mkpath
        file_path.open('w+') do |out|
          if @header
            out.puts @header
            out.puts
          end
          group.sort!
          contents = group.map do |(name, content)|
            content.to_rbs
          end.join("\n")
          out.puts contents
          Orthoses.logger.info("Generate file to #{file_path.to_s}")
        end
      end
    end
  end
end
