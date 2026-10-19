# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the tagged-values compartment text `<g>`. EA renders
        # tagged values as a sub-compartment below attributes with an
        # italic "tags" header followed by `key = value` lines:
        #
        #   <text style="...font-style:italic;...">tags</text>
        #   <text style="...font-style:normal;...">isCollection = false</text>
        #   <text style="...font-style:normal;...">noPropertyType = false</text>
        class TaggedValueRenderer
          HEADER_TEXT = "tags"
          HEADER_X_OFFSET = 5
          LINE_X_OFFSET = 5

          def self.render(tagged_values, bounds:, first_y:, family:, size:, fill: "#000000",
                          size_unit: "px", logical_height: nil)
            line_h = size + 4
            text_blocks = [build_text(bounds.x + centered_x_offset(bounds, size), first_y,
                                      HEADER_TEXT, family, size, fill,
                                      style: "italic", size_unit: size_unit, logical_height: logical_height)]
            tagged_values.each_with_index do |tv, idx|
              text_blocks << build_text(bounds.x + LINE_X_OFFSET, first_y + ((idx + 1) * line_h),
                                        "#{tv.key} = #{tv.value}", family, size, fill,
                                        size_unit: size_unit, logical_height: logical_height)
            end
            %(<g style="#{Style::TEXT_GROUP}">\n#{text_blocks.join("\n")}\n</g>)
          end

          def self.build_text(x, y, content, family, size, fill, style: "normal",
                              size_unit: "px", logical_height: nil)
            TextRenderer.new(content: content, x: x, y: y,
                             family: family, size: size, fill: fill,
                             size_unit: size_unit, logical_height: logical_height,
                             style: style).to_svg
          end
          private_class_method :build_text

          # Center the "tags" header text within the bounds width.
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
