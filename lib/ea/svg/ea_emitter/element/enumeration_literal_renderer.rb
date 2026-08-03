# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Element
        # Emits the enumeration literal compartment text `<g>`. Each
        # literal appears as a separate text element matching EA's
        # encoding:
        #
        #   <text>literal_name</text>
        #
        # Rendered as a third compartment below the attribute
        # compartment for Enumeration classifiers.
        class EnumerationLiteralRenderer
          def self.render(literals, bounds:, first_y:, family:, size:)
            line_h = size + 4
            text_blocks = literals.each_with_index.map do |literal, idx|
              y = first_y + (idx * line_h)
              build_text(bounds.x + 5, y, literal.name.to_s, family, size)
            end
            %(<g style="#{Style::TEXT_GROUP}">\n#{text_blocks.join("\n")}\n</g>)
          end

          def self.build_text(x, y, content, family, size)
            TextRenderer.new(content: content, x: x, y: y,
                              family: family, size: size).to_svg
          end
          private_class_method :build_text
        end
      end
    end
  end
end
