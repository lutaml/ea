# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # The [cap, join] stroke pen a drawing leaves behind. EA never sets a
      # pen on notes and legends: they take whatever the previous drawing
      # left, so the emitter threads the pen from one element to the next.
      module Pen
        ROUND_BEVEL = %w[round bevel].freeze
        SQUARE_BEVEL = %w[square bevel].freeze
        SQUARE_MITER = %w[square miter].freeze

        # The pen in force when nothing has been drawn yet.
        INITIAL = SQUARE_MITER
      end
    end
  end
end
