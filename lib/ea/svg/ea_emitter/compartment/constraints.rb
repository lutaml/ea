# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Constraints compartment. Skipped when the classifier has no
        # constraints. Renders an italic "constraints" header and one
        # "{name}" line per constraint.
        module Constraints
          DEFAULT_TEXT_COLOR = "#000000"

          module_function

          def render(context)
            return nil unless context.constraints&.any?

            Element::ConstraintRenderer.render(
              context.constraints,
              bounds: context.bounds,
              first_y: context.geometry.tagged_value_first_y,
              family: context.family, size: context.size,
              fill: DEFAULT_TEXT_COLOR
            )
          end
        end
      end
    end
  end
end
