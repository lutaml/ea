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
                      :header_top_padding, :header_line_offset,
                      :divider_offset, :attr_line_offset,
                      :attr_first_offset

          def initialize(bounds:, size:, header_lines_count:,
                          attr_lines_count:, op_lines_count:,
                          tagged_values_count:,
                          header_top_padding: 9,
                          header_line_offset: 6,
                          divider_offset: 8,
                          attr_line_offset: 4,
                          attr_first_offset: 7)
            @bounds = bounds
            @size = size
            @header_lines_count = header_lines_count
            @attr_lines_count = attr_lines_count
            @op_lines_count = op_lines_count
            @tagged_values_count = tagged_values_count
            @header_top_padding = header_top_padding
            @header_line_offset = header_line_offset
            @divider_offset = divider_offset
            @attr_line_offset = attr_line_offset
            @attr_first_offset = attr_first_offset
          end

          def header_first_y
            bounds.y + size + (header_top_padding || 9)
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
            return bounds.y + size + (header_top_padding || 9) + 12 unless divider_y

            divider_y + size + (attr_first_offset || 7)
          end

          def attr_bottom_y
            return attr_first_y unless attr_lines_count&.positive?

            attr_first_y + (attr_lines_count - 1) * (size + (attr_line_offset || 4))
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

          def enum_divider_y
            op_bottom_y + size + 5
          end

          def enum_literal_first_y
            enum_divider_y + size + 5
          end

          # Tagged values appear after attributes (or after ops if
          # present). EA does not emit a separate divider — the
          # italic "tags" header marks the compartment.
          def tagged_value_first_y
            return nil unless tagged_values_count&.positive?

            base = attr_bottom_y
            base = op_bottom_y if op_lines_count&.positive?
            base + size + 5
          end
        end
      end
    end
  end
end