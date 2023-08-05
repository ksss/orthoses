module Orthoses
  class Attribute
    CALL_GRAPH = {}

    module Hook
      def attr(*names)
        (CALL_GRAPH[self]||=[]) << [:attr, names]
        super
      end

      def attr_accessor(*names)
        (CALL_GRAPH[self]||=[]) << [:attr_accessor, names]
        super
      end

      def attr_reader(*names)
        (CALL_GRAPH[self]||=[]) << [:attr_reader, names]
        super
      end

      def attr_writer(*names)
        (CALL_GRAPH[self]||=[]) << [:attr_writer, names]
        super
      end
    end

    def initialize(loader)
      CALL_GRAPH.clear
      @loader = loader
    end

    def call
      ::Module.prepend(Hook)

      store = @loader.call

      CALL_GRAPH.dup.each do |base_mod, calls|
        m = base_mod.to_s.match(/#<Class:([\w:]+)>/)
        if m && m[1]
          receiver_name = m[1]
          prefix = "self."
        else
          receiver_name = Utils.module_name(base_mod) or next
          prefix = nil
        end
        content = store[receiver_name]

        calls.each do |(a, names)|
          case a
          when :attr
            if names[1].equal?(true)
              content << "attr_accessor #{prefix}#{names[0]}: untyped"
            elsif names[1].equal?(false)
              content << "attr_reader #{prefix}#{names[0]}: untyped"
            else
              names.each do |name|
                content << "attr_reader #{prefix}#{name}: untyped"
              end
            end
          else
            names.each do |name|
              content << "#{a} #{prefix}#{name}: untyped"
            end
          end
        end
      end

      store
    end
  end
end
