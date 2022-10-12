# frozen_string_literal: true

require 'orthoses/outputable'

module Orthoses
  class CreateFileByName
    prepend Outputable

    def initialize(loader, base_dir:, header: nil, if: nil)
      @loader = loader
      @base_dir = base_dir
      @header = header
      @if = binding.local_variable_get(:if)
    end

    using Utils::Underscore

    def call
      store = @loader.call

      store.each do |name, content|
        next unless @if.nil? || @if.call(name, content)

        file_path = Pathname("#{@base_dir}/#{name.to_s.split('::').map(&:underscore).join('/')}.rbs")
        file_path.dirname.mkpath
        file_path.open('w+') do |out|
          if @header
            out.puts @header
            out.puts
          end
          out.puts content.to_rbs
        end
        Orthoses.logger.info("Generate file to #{file_path.to_s}")
      end
    end
  end
end
