# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the constraints compartment text `<g>`. EA renders
        # constraints as a sub-compartment with an italic "constraints"
        # header followed by `{name}` lines:
        #
        #   <text style="...font-style:italic;...">constraints</text>
        #   <text style="...font-style:normal;...">{pattern}</text>
        class ConstraintRenderer
          HEADER_TEXT = "constraints"
          HEADER_X_OFFSET = 5
          LINE_X_OFFSET = 5

          def self.render(constraints, bounds:, first_y:, family:, size:,
                          fill: "#000000")
            line_h = size + 4
            text_blocks = []
            text_blocks << build_text(
              bounds.x + centered_x_offset(bounds, size), first_y,
              HEADER_TEXT, family, size, fill, style: "italic"
            )
            constraints.each_with_index do |constraint, idx|
              y = first_y + ((idx + 1) * line_h)
              text_blocks << build_text(
                bounds.x + LINE_X_OFFSET, y,
                "{#{constraint.name}}", family, size, fill
              )
            end
            %(<g style="#{Style::TEXT_GROUP}">\n#{text_blocks.join("\n")}\n</g>)
          end

          def self.build_text(x, y, content, family, size, fill, style: "normal")
            TextRenderer.new(content: content, x: x, y: y,
                              family: family, size: size, fill: fill,
                              style: style).to_svg
          end
          private_class_method :build_text

          def self.centered_x_offset(bounds, size)
            text_width = HEADER_TEXT.length * (size / 2)
            centered = (bounds.width / 2 - text_width / 2).floor
            [HEADER_X_OFFSET, centered].max
          end
          private_class_method :centered_x_offset
        end
      end
    end
  end
end
