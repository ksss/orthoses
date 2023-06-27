# frozen_string_literal: true

require 'orthoses/outputable'

module Orthoses
  class CreateFileByName
    prepend Outputable

    def initialize(loader, base_dir:, header: nil, if: nil, depth: nil)
      @loader = loader
      @base_dir = base_dir
      @header = header
      @depth = depth
      @if = binding.local_variable_get(:if)
    end

    using Utils::Underscore

    def call
      store = @loader.call

      store.select! do |name, content|
        @if.nil? || @if.call(name, content)
      end
      grouped = store.group_by do |name, _|
        splitted = name.to_s.split('::')
        (@depth ? splitted[0, @depth] : splitted).join('::')
      end
      grouped.each do |group_name, group|
        file_path = Pathname("#{@base_dir}/#{group_name.split('::').map(&:underscore).join('/')}.rbs")
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
