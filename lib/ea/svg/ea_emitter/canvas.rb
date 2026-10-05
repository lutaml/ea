# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      # Canvas carries the diagram's computed pixel bounds plus the
      # coordinate-translation helpers that align element (0,0) with
      # EA's content origin (35, 40). Bound computation itself is
      # delegated to BoundsCalculator (SRP).
      #
      # Promoted from a Struct.new + `do ... end` block to a proper
      # class so the public API is explicit (attr_reader vs implicit
      # struct fields) and behavior is named rather than implicit.
      # Struct definitions with instance methods conflate "data" and
      # "behavior" — a class keeps them separable while the values
      # stay immutable.
      class Canvas
        # EA's diagram canvas places element (0,0) at SVG (35, 40) —
        # the diagram's content origin inset from the canvas top-left
        # corner. Reverse-engineered from reference SVG byte-diff
        # against the maintenance diagram.
        PX_PER_CM = 37.795275591
        FRAME_INSET_LEFT = 35
        FRAME_INSET_TOP = 40

        attr_reader :min_x, :min_y, :width, :height

        def initialize(min_x:, min_y:, width:, height:)
          @min_x = min_x
          @min_y = min_y
          @width = width
          @height = height
        end

        # Build a Canvas for a diagram by running the bound
        # calculator. Defaults model_index to nil (no canvas-aware
        # element bounds needed) for callers that only need a
        # frame-size estimate.
        def self.from(diagram, model_index: nil)
          min_x, min_y, width, height =
            BoundsCalculator.new(diagram, model_index: model_index).compute
          new(min_x: min_x, min_y: min_y, width: width, height: height)
        end

        # Second-pass canvas over the DRAWN extents captured by the
        # element pass (grown classifiers, autosized packages, plus
        # BoundsCalculator's subtitle reservation). EA sizes the
        # canvas from drawn extents, so diagrams whose lowest/rightmost
        # element grew get a taller/wider canvas than the stored-rect
        # first pass provides.
        def self.from_drawn(diagram, drawn_bounds, model_index: nil)
          base = BoundsCalculator.new(diagram, model_index: model_index)
          pts = []
          drawn_bounds.each_value do |b|
            pts << [b.x, b.y]
            pts << [b.x + b.width, b.y + b.height]
          end
          extra = base.send(:subtitle_points)
          min_x = (pts + extra).map(&:first).min || 0
          min_y = (pts + extra).map(&:last).min || 0
          max_x = (pts + extra).map(&:first).max || 0
          max_y = (pts + extra).map(&:last).max || 0
          return from(diagram, model_index: model_index) if pts.empty?

          new(min_x: min_x, min_y: min_y,
              width: (max_x - min_x) + BoundsCalculator::INSET_LEFT +
                     BoundsCalculator::INSET_RIGHT,
              height: (max_y - min_y) + BoundsCalculator::INSET_TOP +
                      BoundsCalculator::INSET_BOTTOM)
        end

        def view_box
          "0 0 #{width} #{height}"
        end

        def width_cm
          format_cm(width)
        end

        def height_cm
          format_cm(height)
        end

        # Translate a content-space point into SVG-space. EA insets
        # the content area from the canvas top-left by
        # FRAME_INSET_LEFT/TOP.
        def translate_x(x)
          x - min_x + FRAME_INSET_LEFT
        end

        def translate_y(y)
          y - min_y + FRAME_INSET_TOP
        end

        # Compact coordinate formatter. Integers lose the decimal
        # point; floats keep up to two digits with trailing zeros
        # stripped (matches EA's emitted numeric format).
        def self.coord(value)
          return value.to_i.to_s if value == value.to_i

          format("%.2f", value).sub(/\.?0+$/, "")
        end

        private

        def format_cm(px)
          return "0cm" if px.nil? || px.zero?

          cm = (px / PX_PER_CM.to_f)
          format("%.2fcm", cm)
        end
      end
    end
  end
end