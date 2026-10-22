# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Label
        # Plain leftward target roles end three pixels before the anchor.
        module PlainTargetSeat
          def self.position(connector:, anchor:, box:, width:)
            return nil unless width
            return nil unless (eligible_connector?(connector) && zero_role_box?(box)) ||
                              (lateral_connector?(connector) && lateral_zero_box?(box))

            [anchor[0] - width - 3, anchor[1] - 7]
          end

          # EMPIRICAL FIT: an unmoved ALN=0 13px role on a width-0 derived
          # lateral-horizontal association seats like the plain target above
          # (test B58D1A53 +role2, the only such leftward target).
          def self.unmoved_lateral_role?(connector, box)
            !box.nil? && lateral_connector?(connector) && lateral_zero_box?(box)
          end

          def self.lateral_connector?(connector)
            style = connector.style.to_h
            connector.connector_type == "Association" &&
              style.values_at(:mode, :lwidth, :tree) == %w[3 0 LH] &&
              (style[:derived_lateral_line] || style[:umldi_route]) == true
          end

          def self.lateral_zero_box?(box)
            box.values_at("alignment", "cy") == [0, 13] &&
              box.values_at("ox", "oy").map(&:to_i) == [0, 0]
          end

          # EMPIRICAL FIT: a stored ALN=2 role box on a horizontal
          # arrival keeps its mirrored corner, text_pos, and is drawn
          # outside it: a leftward arrival (OX < 0) ends 2px short of the
          # corner (7 samples in basic: 6E95B74E, 4F421236, 2AAB709F,
          # 4DBDAB9E, D2FA55D3 x2, width 30); a rightward arrival (OX > 0)
          # starts 4px past it (basic D351FC34, F32E5AFE roleOne, width 41).
          # Eligibility and placement of a stored ALN=2 target role: a plain
          # Association, mode 3 / width 0 stored ray, a single-line (CY 13/14)
          # unstyled ALN=2 box, no target stereotype, in the eligible font.
          def self.aligned_role(connector:, heading:, text_pos:, box:, role:, width:,
                                font_eligible:, target_stereotype:)
            return nil unless font_eligible && !role.to_s.empty? && target_stereotype.to_s.empty?
            return nil unless aligned_connector?(connector) && aligned_box?(box)

            aligned_position(heading: heading, text_pos: text_pos, box: box, width: width)
          end

          def self.aligned_connector?(connector)
            style = connector.style.to_h
            connector.connector_type == "Association" &&
              style.values_at(:mode, :lwidth, :tree) == ["3", "0", nil] && style[:stored_association_ray]
          end

          def self.aligned_box?(box)
            return false unless box && box["alignment"] == 2 && [13, 14].include?(box["cy"])
            return false unless box["ox"] && box["oy"] && [nil, -1].include?(box["color"])

            box["rotation"].to_i.zero? && box["direction"].to_i.zero? &&
              box.values_at("hidden", "bold", "italic", "underline").none?
          end

          def self.aligned_position(heading:, text_pos:, box:, width:)
            return nil unless width && text_pos && heading && heading[1].zero?

            ox = box["ox"].to_i
            if heading[0].negative? && ox.negative?
              [text_pos[0] - width - 2, text_pos[1]]
            elsif heading[0].positive? && ox.positive?
              [text_pos[0] + 4, text_pos[1]]
            end
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
