# frozen_string_literal: true

module Ea
  module Shapescript
    # One rendered shape primitive. Carries type + params
    # ready for SVG emission.
    Shape = Struct.new(:kind, :params, keyword_init: true) do
      # @return [Boolean] true when this shape is a rectangle
      def rectangle?
        kind == :rectangle
      end

      def ellipse?
        kind == :ellipse
      end

      def polygon?
        kind == :polygon
      end

      def line?
        kind == :line
      end

      def path?
        kind == :path
      end

      def label?
        kind == :label
      end
    end
  end
end
