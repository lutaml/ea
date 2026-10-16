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
          module_function

          def render(context)
            return nil unless context.constraints&.any?
            return nil unless context.geometry.constraints_first_y

            divider = Element::DividerRenderer.render(
              context.bounds, y: context.geometry.constraints_divider_y,
                              stroke: context.stroke, stroke_width: context.stroke_width
            )
            "#{divider}\n#{Element::ConstraintRenderer.render_compartment(context)}"
          end
        end
      end
    end
  end
end
