# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Tagged value compartment. Skipped when no tagged values
        # or when geometry cannot fit them.
        module TaggedValues
          DEFAULT_TEXT_COLOR = "#000000"

          module_function

          def render(context)
            return nil unless context.tagged_values.any?
            return nil unless context.geometry.tagged_value_first_y

            Element::TaggedValueRenderer.render(
              context.tagged_values,
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
