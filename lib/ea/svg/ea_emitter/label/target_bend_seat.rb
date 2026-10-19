# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Label
        # Moved plain target pairs on saved vertical stairs use the first
        # bend, opposing 8px gutters and a baseline 3px above the saved OY.
        module TargetBendSeat
          def self.reference(points)
            return nil unless points.size == 4

            first, bend, corner, last = points
            bend if descending_leg?(first, bend) && descending_leg?(corner, last) &&
                    bend[1] == corner[1] && bend[0] != corner[0]
          end

          def self.descending_leg?(first, last)
            first[0] == last[0] && first[1] < last[1]
          end
          private_class_method :descending_leg?

          def self.positions(connector:, bend:, text_box:, mult_box:, width:)
            return nil unless bend && width && connector.connector_type == "Association"
            return nil unless connector.style.to_h.values_at(:mode, :lwidth, :tree) == %w[3 0 V]
            return nil unless moved_box?(text_box, 31) && moved_box?(mult_box, 16)

            [position(bend, text_box, -width - 8), position(bend, mult_box, 8)]
          end

          def self.position(bend, box, inset)
            [bend[0] + box["ox"].to_i + inset, bend[1] + box["oy"].to_i - 3]
          end
          private_class_method :position

          def self.moved_box?(box, height)
            box["alignment"] == 1 && box["cy"] == height &&
              [box["ox"].to_i, box["oy"].to_i] != [0, 0]
          end
          private_class_method :moved_box?
        end
      end
    end
  end
end
