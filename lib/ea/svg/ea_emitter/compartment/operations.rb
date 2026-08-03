# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Operation compartment: divider line + operation signatures.
        # Skipped when no operations or when geometry cannot fit them.
        module Operations
          module_function

          def render(context)
            return nil unless context.op_lines.any?
            return nil unless context.geometry.op_first_y
            return nil unless context.classifier

            parts = []
            if context.attr_lines.any?
              parts << Element::DividerRenderer.render(
                context.bounds,
                y: context.geometry.op_divider_y,
                stroke: context.stroke,
                stroke_width: context.stroke_width
              )
            end
            parts << Element::OperationRenderer.render(
              context.classifier.operations,
              bounds: context.bounds,
              first_y: context.geometry.op_first_y,
              family: context.family, size: context.size
            )
            parts.join("\n")
          end
        end
      end
    end
  end
end
