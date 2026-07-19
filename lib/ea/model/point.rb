# frozen_string_literal: true

module Ea
  module Model
    # 2D point in diagram pixel coordinates.
    class Point < Base
      attribute :x, :integer
      attribute :y, :integer

      json do
        map "x", to: :x
        map "y", to: :y
      end
    end
  end
end
