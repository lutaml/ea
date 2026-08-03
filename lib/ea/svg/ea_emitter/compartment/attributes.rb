# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Attribute compartment. Skipped when no attribute lines.
        module Attributes
          module_function

          def render(context)
            return nil if context.attr_lines.empty?

            Element::AttributeRenderer.render(
              context.attr_lines,
              bounds: context.bounds,
              first_y: context.geometry.attr_first_y,
              family: context.family, size: context.size, size_unit: context.size_unit,
              fill: context.theme.attribute_text_color,
              visibility_x_offset: context.theme.attribute_spec.visibility_x_offset,
              content_x_offset: context.theme.attribute_spec.content_x_offset
            )
          end
        end
      end
    end
  end
end
