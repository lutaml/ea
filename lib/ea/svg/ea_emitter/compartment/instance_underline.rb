# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Instance-name underline for object diagrams. EA draws a
        # short horizontal line just below each instance name to
        # denote that it is an instance (UML convention). Rendered
        # only when the diagram's `diagram_type` is "Object".
        module InstanceUnderline
          Y_OFFSET = 2
          WIDTH_FACTOR = 0.65

          module_function

          def render(context)
            return nil unless context.diagram
            return nil unless object_diagram?(context)
            return nil if context.header_lines.empty?

            name_line = context.header_lines.last
            text = name_line.first.to_s
            return nil if text.empty?

            underline_path(context, text)
          end

          def object_diagram?(context)
            context.diagram && context.diagram.diagram_type == "Object"
          end
          module_function :object_diagram?

          def underline_path(context, text)
            bounds = context.bounds
            text_width = TextRenderer.estimate_width(text, context.size,
                                                     WIDTH_FACTOR)
            x_start = bounds.x + (bounds.width - text_width) / 2.0
            y_pos = context.geometry.header_first_y + Y_OFFSET
            build_path_tag(x_start, y_pos, text_width)
          end
          module_function :underline_path

          def build_path_tag(x_start, y_pos, text_width)
            x_end = x_start + text_width
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
