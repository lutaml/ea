# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Horizontal divider between header and the first content
        # compartment (attributes / operations / literals / tagged
        # values). Skipped when there is no content below.
        module HeaderDivider
          module_function

          def render(context)
            return nil unless context.geometry
            return nil unless context.geometry.divider_y
            return nil unless divider_required?(context)

            Element::DividerRenderer.render(
              context.bounds,
              y: context.geometry.divider_y,
              stroke: context.stroke,
              stroke_width: context.stroke_width
            )
          end

          # EA shows a header divider on Object diagrams when the
          # element is large enough to hold a slot compartment (height
          # > 50). The starter Object diagram uses 90×50 boxes with
          # no slots and no divider; richer Object diagrams use
          # 133×53+ boxes with the divider always present. On
          # HandDraw diagrams (Domain Model), every element shows a
          # divider regardless of content. For other diagrams the
          # divider is shown only when there is content below the
          # header.
          def divider_required?(context)
            return true if hand_draw?(context)
            return object_element_with_slots?(context) if object_diagram?(context)

            context.content_below_header?
          end

          def object_diagram?(context)
            context.diagram && context.diagram.diagram_type == "Object"
          end

          def hand_draw?(context)
            context.diagram && context.diagram.hand_draw
          end

          def object_element_with_slots?(context)
            context.bounds && context.bounds.height.to_i > 50
          end
        end
      end
    end
  end
end
