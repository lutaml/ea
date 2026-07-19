# frozen_string_literal: true

module Ea
  module Model
    # Rectangular bounds in diagram pixel coordinates. Used by
    # DiagramElement to record where a classifier is placed on a
    # diagram.
    class Bounds < Base
      attribute :x, :integer
      attribute :y, :integer
      attribute :width, :integer
      attribute :height, :integer

      json do
        map "x", to: :x
        map "y", to: :y
        map "width", to: :width
        map "height", to: :height
      end
    end
  end
end
