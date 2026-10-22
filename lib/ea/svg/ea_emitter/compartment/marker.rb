# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # {root}/{leaf} marker compartment. EA seats the marker line
        # DIRECTLY BELOW the header divider, BEFORE the attribute
        # rows (each marker row shifts the attributes down one row).
        # Real OCL constraints render trailing, after the content —
        # the two are distinct compartments.
        module Marker
          # The pen the first group of this compartment leaves behind.
          def self.pen(_context)
            Pen::ROUND_BEVEL
          end

          module_function

          def render(context)
            return nil unless context.marker_lines&.any?
            return nil unless context.geometry.marker_first_y

            Element::ConstraintRenderer.render(
              context.marker_lines,
              bounds: context.bounds,
              first_y: context.geometry.marker_first_y,
              family: context.family, size: context.size,
              right_inset: 6
            )
          end
        end
      end
    end
  end
end
