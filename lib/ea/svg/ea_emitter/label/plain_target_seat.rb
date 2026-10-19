# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Label
        # Plain leftward target roles end three pixels before the anchor.
        module PlainTargetSeat
          def self.position(connector:, anchor:, box:, width:)
            return nil unless width && eligible_connector?(connector) && zero_role_box?(box)

            [anchor[0] - width - 3, anchor[1] - 7]
          end

          def self.eligible_connector?(connector)
            connector.connector_type == "Association" &&
              connector.style.to_h.values_at(:mode, :lwidth, :tree, :plain_target_seat) == ["3", "2", nil, true]
          end

          def self.zero_role_box?(box)
            box.values_at("alignment", "cy") == [1, 18] &&
              box.values_at("ox", "oy").map(&:to_i) == [0, 0]
          end
        end
      end
    end
  end
end
