# frozen_string_literal: true

require 'orthoses/outputable'

module Orthoses
  class CreateFileByName
    prepend Outputable

    def initialize(loader, base_dir:, header: nil)
      @loader = loader
      @base_dir = base_dir
      @header = header
    end

    using(Module.new {
      refine String do
        # avoid load active_support
        def underscore
          return self unless /[A-Z-]|::/.match?(self)
          word = self.to_s.gsub("::", "/")
          word.gsub!(/(?:(?<=([A-Za-z\d]))|\b)((?-mix:(?=a)b))(?=\b|[^a-z])/) { "#{$1 && '_' }#{$2.downcase}" }
          word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
          word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
          word.tr!("-", "_")
          word.downcase!
          word
        end
      end
    })

    def call
      store = @loader.call

      store.each do |name, content|
        rbs = begin
          content.to_rbs
        rescue NameError, LoadError => err
          Orthoses.logger.error(err.inspect)
          next
        end
        file_path = Pathname("#{@base_dir}/#{name.to_s.split('::').map(&:underscore).join('/')}.rbs")
        file_path.dirname.mkpath
        file_path.open('w+') do |out|
          if @header
            out.puts @header
            out.puts
          end
          out.puts rbs
        end
        Orthoses.logger.info("Generate file to #{file_path.to_s}")
      end
    end
  end
end
