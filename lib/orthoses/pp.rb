# frozen_string_literal: true

module Orthoses
  # Debug current stored values
  #   use Orthoses::PP
  class PP
    def initialize(loader)
      @loader = loader
    end

    def call
      pp @loader.call
    end
  end
end
