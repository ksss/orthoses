module Orthoses
  class CreateFileByName
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

    def call(env)
      @loader.call(env).each do |name, lines|
        next if name.start_with?('#')
        begin
          name_spaces = Orthoses::Util.string_to_namespaces(name)
        rescue ArgumentError => e
          # <= 6.1 ActiveSupport::Dependencies#load_missing_constant
          next if e.message.end_with?("has been removed from the module tree but is still active!")
          raise
        end

        path_base = (Util::VIRTUAL_NAMESPACE.match(name)&.[](:name) || name).split('::').map(&:underscore)
        path = path_base.join('/') << ".rbs"
        indent = +"  " * name_spaces.length
        rbs = []

        # header
        if @header
          rbs << @header
          rbs << ""
        end
        rbs.concat name_spaces.map.with_index { |name_space, indent| +"  " * indent << name_space }

        # body
        bodies = lines.flatten.compact.map { |line| "#{indent}#{line}" }
        rbs.concat bodies if 0 < bodies.length

        # footer
        rbs.concat name_spaces.each_with_index.reverse_each.map { |_, indent| +"  " * indent << "end" }

        path_name = Pathname(@base_dir) / path
        path_name.dirname.mkpath
        path_name.write("#{rbs.join("\n")}\n")
      end
    end
  end
end
