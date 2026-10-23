# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Label
        # Plain leftward roles end before the stored corner, mirroring
        # the 3px gutter and baseline of the rightward role seat.
        module PlainSourceSeat
          # EMPIRICAL FIT, stored 13px role boxes moved left of a leftward
          # straight source on mode 3, width 0: ALN=0 ends 3px before the
          # corner (basic D351FC34, F32E5AFE roleTwo, Association), ALN=2
          # 2px before it (basic 6D0349D5 role b, Aggregation); both sit
          # 7px above the corner like the Aggregation case below.
          # Only cy=13 boxes are measured: every negative-OX LLT box with ALN 0 or
          # 2 in basic, test, simple, ArcGIS and PLATEAU has cy=13 (cy=14 occurs
          # only with ALN=1), so the ALN=2 target seat's 13-or-14 tolerance is
          # not extended to the source.
          STORED_INSETS = { 0 => 3, 2 => 2 }.freeze

          def self.position(connector:, anchor:, box:, width:)
            return nil unless width

            inset = stored_inset(connector, box)
            inset = 3 if inset.nil? && eligible_connector?(connector) && moved_role_box?(box)
            return nil unless inset

            [anchor[0] + box["ox"].to_i - width - inset, anchor[1] + box["oy"].to_i - 7]
          end

          def self.stored_inset(connector, box)
            return nil unless %w[Association Aggregation].include?(connector.connector_type)
            return nil unless connector.style.to_h.values_at(:mode, :lwidth, :tree) == ["3", "0", nil]
            return nil unless box["cy"] == 13 && box["ox"].to_i.negative?

            STORED_INSETS[box["alignment"]]
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
