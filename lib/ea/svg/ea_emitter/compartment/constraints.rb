# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Real (OCL) constraints compartment. Skipped when the
        # classifier has no constraints — the {root}/{leaf} marker
        # renders in its own Marker compartment between the divider
        # and the attributes. EA seats OCL constraint lines after the
        # content and suppresses them when they would overflow the
        # stored box height (never truncates rows).
        module Constraints
          DEFAULT_TEXT_COLOR = "#000000"

          module_function

          def render(context)
            return nil unless context.constraints&.any?
            return nil unless context.geometry.tagged_value_first_y

            first_y = context.geometry.tagged_value_first_y
            line_h = context.size + 6
            last_y = first_y + (context.constraints.size - 1) * line_h
            return nil if last_y + 4 > context.bounds.y + context.bounds.height

            Element::ConstraintRenderer.render(
              context.constraints,
              bounds: context.bounds,
              first_y: first_y,
              family: context.family, size: context.size,
              fill: DEFAULT_TEXT_COLOR
            )
          end
        end
      end
    end
  end
end
