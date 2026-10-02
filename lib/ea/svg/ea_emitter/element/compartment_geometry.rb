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
          attr_reader :bounds, :size, :header_lines_count,
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
                          attr_first_offset: 7)
            @bounds = bounds
            @size = size
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
          end

          def header_first_y
            bounds.y + size + (header_top_padding || 12)
          end

          # Y of the divider line between header and the rest.
          # Returns nil when there's no header content to separate
          # from empty below-header content.
          def divider_y
            return nil if header_lines_count.zero?

            header_first_y +
              ([header_lines_count, 1].max - 1) * (size + (header_line_offset || 6)) +
              (divider_offset || 8)
          end

          def attr_first_y
            base = raw_attr_first_y
            return base unless marker_count.to_i.positive?

            # EA renders the {root}/{leaf} marker compartment BETWEEN
            # the header divider and the attributes: its rows occupy
            # (attr_base - 9) onward at the 13px pitch, and attributes
            # shift down one row per marker line. Real OCL constraints
            # do NOT shift attributes — they render trailing.
            # Corpus-verified (TK_PositionType: name +13 {root} +22
            # first-attr; MD_Identification keeps attrs at +22 despite
            # carrying OCL constraints).
            base + (size + 6) * marker_count
          end

          # First marker-line baseline: one row slot above where
          # attributes would start without markers.
          def marker_first_y
            return nil unless marker_count.to_i.positive?

            raw_attr_first_y - 9
          end

          def raw_attr_first_y
            return bounds.y + size + (header_top_padding || 12) + 12 unless divider_y

            divider_y + size + (attr_first_offset || 7)
          end

          def attr_bottom_y
            return attr_first_y unless attr_lines_count&.positive?

            attr_first_y + (attr_lines_count - 1) * (size + (attr_line_offset || 6))
          end

          def op_divider_y
            attr_bottom_y + size + 5
          end

          def op_first_y
            return nil unless op_lines_count&.positive?

            op_divider_y + size + 5
          end

          def op_bottom_y
            return op_divider_y unless op_lines_count&.positive?

            op_first_y + (op_lines_count - 1) * (size + 4)
          end

          # EA draws a single divider under the header and seats
          # enumeration literals directly after it (+14 at 7pt),
          # exactly like attribute rows - no second divider and no
          # "literals" header. Verified against EA-published SVGs.
          def enum_literal_first_y
            return nil unless divider_y

            divider_y + size + (attr_first_offset || 7)
          end

          # Tagged values appear after attributes (or after ops if
          # present). EA does not emit a separate divider — the
          # italic "tags" header marks the compartment. Constraints
          # render ABOVE the attributes (constraints_first_y), not
          # here.
          def tagged_value_first_y
            return nil unless tagged_values_count.to_i.positive? ||
                              constraints_count.to_i.positive?

            content_bottom_y + size + 5
          end

          # The lowest content edge among attributes, enum literals,
          # operations, and constraints — the anchor for trailing
          # compartments and the autosize height.
          def content_bottom_y
            bottoms = [attr_bottom_y]
            bottoms << enum_literals_bottom_y if enum_literals_count.to_i.positive?
            bottoms << op_bottom_y if op_lines_count.to_i.positive?
            bottoms.compact.max
          end

          def enum_literals_bottom_y
            return nil unless enum_literal_first_y

            enum_literal_first_y + ([enum_literals_count, 1].max - 1) * (size + 6)
          end
        end
      end
    end
  end
end