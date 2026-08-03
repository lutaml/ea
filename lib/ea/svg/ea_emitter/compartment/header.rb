# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Header compartment: stereotype label + class name. Skips
        # rendering when the classifier produces no header lines.
        module Header
          module_function

          def render(context)
            return nil if context.header_lines.empty?

            Element::HeaderRenderer.render(
              context.header_lines,
              bounds: context.bounds,
              first_y: context.geometry.header_first_y,
              family: context.family, size: context.size, size_unit: context.size_unit,
              fill: context.theme.text_color,
              weight_normal: context.theme.text_weight_normal,
              weight_bold: context.theme.text_weight_bold,
              stroke_in_text: context.theme.stroke_in_text_color,
              width_factor: context.theme.text_width_factor,
              line_offset: context.theme.compartments.header_line_offset
            )
          end
        end
      end
    end
  end
end
