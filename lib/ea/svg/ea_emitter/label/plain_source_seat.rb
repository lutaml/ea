# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Label
        # Plain leftward roles end before the stored corner, mirroring
        # the 3px gutter and baseline of the rightward role seat.
        module PlainSourceSeat
          def self.position(connector:, anchor:, box:, width:)
            return nil unless width && eligible_connector?(connector) && moved_role_box?(box)

            [anchor[0] + box["ox"].to_i - width - 3, anchor[1] + box["oy"].to_i - 7]
          end

          def self.eligible_connector?(connector)
            connector.connector_type == "Aggregation" &&
              connector.style.to_h.values_at(:mode, :lwidth, :tree, :plain_source_seat) == ["3", "2", nil, true]
          end

          def self.moved_role_box?(box)
            box.values_at("alignment", "cy") == [1, 18] &&
              box.values_at("ox", "oy").map(&:to_i) != [0, 0]
          end
        end
      end
    end
  end
end
