# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Y-coordinate calculator for the compartments of an element
        # box: header text, header divider, attribute rows, operation
        # rows, enum literals, tagged-value rows.
        #
        # Owns its own coordinate math; the rest of Elements only
        # reads `header_first_y`, `divider_y`, `attr_first_y`, etc.
        # Construction takes the bounds, font size, line counts,
        # and per-region offsets from the theme.
        #
        # Extracted from Elements.rb to keep each concern in one
        # place (MECE). Element rendering reads these values;
        # coordinate math changes don't ripple into rendering.
        class CompartmentGeometry
          attr_reader :bounds, :size, :header_lines_count, :header_ghost,
                      :header_ghost_tight,
                      :attr_lines_count, :op_lines_count,
                      :tagged_values_count,
                      :constraints_count,
                      :marker_count,
                      :enum_literals_count,
                      :header_top_padding, :header_line_offset,
                      :divider_offset, :attr_line_offset,
                      :attr_first_offset

          def initialize(bounds:, size:, header_lines_count:,
                          attr_lines_count:, op_lines_count:,
                          tagged_values_count:,
                          constraints_count: 0,
                          marker_count: 0,
                          enum_literals_count: 0,
                          header_top_padding: 12,
                          header_line_offset: 6,
                          divider_offset: 8,
                          attr_line_offset: 6,
                          attr_first_offset: 7,
                          attr_group_lead: 0,
                         family: nil, size_unit: "pt", logical_height: nil,
                          header_ghost: false,
                          header_ghost_tight: false)
            @bounds = bounds
            @size = size
            @family = family
            @size_unit = size_unit
            @logical_height = logical_height
            @header_lines_count = header_lines_count
            @attr_lines_count = attr_lines_count
            @op_lines_count = op_lines_count
            @tagged_values_count = tagged_values_count
            @constraints_count = constraints_count
            @marker_count = marker_count
            @enum_literals_count = enum_literals_count
            @header_top_padding = header_top_padding
            @header_line_offset = header_line_offset
            @divider_offset = divider_offset
            @attr_line_offset = attr_line_offset
            @attr_first_offset = attr_first_offset
            @attr_group_lead = attr_group_lead
            @header_ghost = header_ghost
            @header_ghost_tight = header_ghost_tight
          end

          def line_height(offset)
            Ea::Fonts::Metrics.compartment_line_height(
              size, family: @family, unit: @size_unit, offset: offset, logical_height: @logical_height
            )
          end
          private :line_height

          # A source font can export at the same point size with a smaller
          # logical cell. Seat its first baseline using the same height delta
          # as its row pitch, without changing compact-font spacing.
          def source_baseline_adjustment
            nominal_height = Ea::Fonts::Metrics.compartment_line_height(
              size, family: @family, unit: @size_unit, offset: 0
            )
            line_height(0) - nominal_height
          end
          private :source_baseline_adjustment

          def header_first_y
            bounds.y + size + (header_top_padding || 12) + source_baseline_adjustment
          end

          # Y of the divider line between header and the rest.
          # Returns nil when there's no header content to separate
          # from empty below-header content.
          # {root}/{leaf} marker lines sit INSIDE the header region:
          # each pushes the divider down one row slot (E0C65C12/
          # TK_PositionType: name at 69, EA divider at 90 = our old
          # 77 + 13, attrs follow at 104 on both sides).
          def divider_y
            return nil if header_lines_count.zero?

            # The off-canvas parent ghost shifts every following
            # header line +3, and the divider tracks the LAST header
            # baseline + 8 (936AA434: ghost 100, stereo 116 = +16).
            ghost_shift = header_ghost ? (header_ghost_tight ? 3 : 6) : 0

            header_first_y +
              ([header_lines_count, 1].max - 1) * line_height(header_line_offset || 6) +
              ghost_shift +
              (marker_count.to_i * line_height(6)) +
              (divider_offset || 8)
          end

          def attr_first_y
            raw_attr_first_y
          end

          # First marker-line baseline: its own row between the name
          # and the divider it pushes down (E0C65C12: name 69, {root}
          # 82, divider 90 = {root} + 8).
          def marker_first_y
            return nil unless marker_count.to_i.positive?
            return nil unless divider_y

            divider_y - 8
          end

          def raw_attr_first_y
            return header_first_y + 12 unless divider_y

            divider_y + line_height((attr_first_offset || 7) - 1) + 1
          end

          def attr_bottom_y
            return attr_first_y unless attr_lines_count&.positive?

            attr_first_y + (attr_lines_count - 1) * line_height(attr_line_offset || 6) +
              @attr_group_lead.to_i
          end

          def op_divider_y
            attr_bottom_y + size + 5
          end

          # EA's op block: first row 21 below the last attribute row
          # (9pt... 7pt: attr_bottom + 21), uniform 13px pitch across
          # attrs AND ops (6D4C665D: attrs ..520, ops 541..658 step 13).
          # Attribute-empty boxes anchor on the divider instead:
          # first op at divider + 14 (001A64C1: EA ops 104 vs our
          # 125 when attrs were absent).
          def op_first_y
            return nil unless op_lines_count&.positive?

            if attr_lines_count.to_i.positive?
              attr_bottom_y + size + 14
            else
              divider_y + size + 7
            end
          end

          def op_bottom_y
            return op_divider_y unless op_lines_count&.positive?

            op_first_y + (op_lines_count - 1) * line_height(6)
          end

          # EA draws a single divider under the header and seats
          # the enumeration caption directly after it (+14 at 7pt),
          # followed by the literal rows without a second divider.
          def enum_literal_first_y
            return nil unless divider_y

            divider_y + line_height((attr_first_offset || 7) - 1) + 1
          end

          # OCL constraints follow the regular content with a divider and caption.
          # Suppress the whole compartment when its last row cannot fit.
          def constraints_first_y
            return nil unless constraints_count.to_i.positive?

            first_y = constraints_caption_y
            first_y if first_y + constraints_count * (size + 5) + 4 <= bounds.y + bounds.height
          end

          def constraints_caption_y
            (regular_content_bottom_y || raw_attr_first_y) + size + 13
          end

          def constraints_divider_y
            constraints_first_y - size - 7 if constraints_first_y
          end

          def constraints_bottom_y
            constraints_first_y + constraints_count * (size + 5) if constraints_first_y
          end

          # Tagged values follow the last visible content compartment.
          def tagged_value_first_y
            return nil unless tagged_values_count.to_i.positive?

            (content_bottom_y || raw_attr_first_y) + size + 5
          end

          # The lowest content edge among attributes, enum literals,
          # operations, and constraints — the anchor for trailing
          # compartments and the autosize height.
          # Nil when no compartment rows render (header-only box):
          # the autosize gate must not treat the empty-compartment
          # anchor as content.
          def content_bottom_y
            [regular_content_bottom_y, constraints_bottom_y].compact.max
          end

          def regular_content_bottom_y
            bottoms = []
            bottoms << attr_bottom_y if attr_lines_count.to_i.positive?
            bottoms << enum_literals_bottom_y if enum_literals_count.to_i.positive?
            bottoms << op_bottom_y if op_lines_count.to_i.positive?
            bottoms.max
          end

          def enum_literals_bottom_y
            return nil unless enum_literal_first_y

            enum_literal_first_y + ([enum_literals_count, 1].max - 1) * line_height(6)
          end
        end
      end
    end
  end
end
