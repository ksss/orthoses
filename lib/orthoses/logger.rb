module Orthoses
  class Logger
    def initialize(loader, level: ::Logger::INFO)
      @loader = loader
      @level = level
    end

    def call(env)
      logger = ::Logger.new(env[:errors])
      logger.level = @level

      env[:logger] = logger
      @loader.call(env)
    end
  end
end
