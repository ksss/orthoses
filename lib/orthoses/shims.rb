# RBS 3.8
unless RBS::TypeName.singleton_class.method_defined?(:parse)
  module RBS
    class TypeName
      def self.parse(string)
        absolute = string.start_with?("::")

        *path, name = string.delete_prefix("::").split("::").map(&:to_sym)
        raise unless name

        TypeName.new(
          name: name,
          namespace: RBS::Namespace.new(path: path, absolute: absolute)
        )
      end
    end
  end
end
