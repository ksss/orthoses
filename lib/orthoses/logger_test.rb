# frozen_string_literal: true

module LoggerTest
  def test_logger(t)
    middleware = Class.new do
      def initialize(loader)
        @loader = loader
      end

      def call(env)
        @loader.call(env)
        env[:logger].info("logging")
      end
    end

    stack = middleware.new(Orthoses::Logger.new(->(_){}))
    out = StringIO.new
    stack.call({ errors: out })
    unless out.string.end_with?("logging\n")
      t.error("[Logger] cannot call Logger")
    end
  end
end
