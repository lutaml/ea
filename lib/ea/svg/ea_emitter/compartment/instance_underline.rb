# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Instance-name underline for object diagrams. EA draws a
        # short horizontal line below each instance name to denote
        # that it is an instance (UML convention).
        module InstanceUnderline
          Y_OFFSET = 1

          module_function

          def render(context)
            return nil unless context.diagram
            return nil unless object_diagram?(context)
            return nil if context.header_lines.empty?

            header = Element::HeaderRenderer.line_layout(
              context.header_lines,
              bounds: context.bounds,
              first_y: context.geometry.header_first_y,
              family: context.family,
              size: context.size,
              size_unit: context.size_unit,
              logical_height: context.logical_height,
              weight_normal: context.theme.text_weight_normal,
              weight_bold: context.theme.text_weight_bold,
              width_factor: context.theme.text_width_factor,
              line_offset: context.theme.compartments.header_line_offset
            ).last
            return nil unless header && !header.text.to_s.empty?

            underline_path(header)
          end

          def object_diagram?(context)
            context.diagram && context.diagram.diagram_type == "Object"
          end
          module_function :object_diagram?

          def underline_path(header)
            build_path_tag(header.x, header.y + Y_OFFSET, header.text_length)
          end
          module_function :underline_path

          def build_path_tag(x_start, y_pos, text_length)
            x_end = x_start + text_length
            coords = format_coords(x_start, y_pos, x_end)
            d = "M #{coords[:x1]} #{coords[:y1]} L #{coords[:x2]} #{coords[:y1]}"
            style = "stroke-width:1;stroke-linecap:square;" \
                    "stroke-linejoin:miter; fill:none; stroke:#000000;" \
                    " stroke-opacity:1.00"
            %(<g style="#{style}">\n  <path d="#{d}" shape-rendering="auto"/>\n</g>)
          end
          module_function :build_path_tag

          def format_coords(x_start, y_pos, x_end)
            {
              x1: Ea::Svg::EaEmitter::Canvas.coord(x_start),
              x2: Ea::Svg::EaEmitter::Canvas.coord(x_end),
              y1: Ea::Svg::EaEmitter::Canvas.coord(y_pos)
            }
          end
          module_function :format_coords
        end
      end
    end
  end
end
