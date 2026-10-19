# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Label
        # Plain moved source pairs on descending stairs use opposing 3px
        # gutters and a baseline 18px below the stored source dock.
        module SourceStairSeat
          def self.positions(connector:, anchor:, text_box:, mult_box:, width:)
            return nil unless width && connector.connector_type == "Aggregation"
            return nil unless connector.style.to_h.values_at(:mode, :lwidth, :tree) == %w[3 0 V]
            return nil unless descending_stair?(connector.waypoints)
            return nil unless moved_box?(text_box) && moved_box?(mult_box)

            [position(anchor, text_box, -width - 3), position(anchor, mult_box, 3)]
          end

          def self.descending_stair?(waypoints)
            return false unless waypoints.size == 4 && waypoints.all?(&:position)

            first, bend, corner, last = waypoints.map(&:position)
            descending_leg?(first, bend) && descending_leg?(corner, last) &&
              horizontal_leg?(bend, corner)
          end
          private_class_method :descending_stair?

          def self.descending_leg?(first, last)
            first.x == last.x && first.y < last.y
          end
          private_class_method :descending_leg?

          def self.horizontal_leg?(first, last)
            first.y == last.y && first.x != last.x
          end
          private_class_method :horizontal_leg?

          def self.position(anchor, box, inset)
            [anchor[0] + box["ox"].to_i + inset, anchor[1] + box["oy"].to_i + 18]
          end
          private_class_method :position

          def self.moved_box?(box)
            box["alignment"] == 1 && box["cy"] == 18 &&
              [box["ox"].to_i, box["oy"].to_i] != [0, 0]
          end
          private_class_method :moved_box?
        end
      end
    end
  end
end
