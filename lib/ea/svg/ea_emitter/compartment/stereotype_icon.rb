# frozen_string_literal: true

module Ea
  module Svg
    module EaEmitter
      module Compartment
        # Stereotype decorator icon compartment. Emits the small
        # symbolic polygon that EA renders inside an element's body
        # when a stereotype provides a custom icon (FeatureType
        # diamond, Type polygon, etc.). Delegates to
        # Element::StereotypeIconRenderer.
        #
        # Rendered after the header so the icon sits inside the
        # element body below the stereotype label.
        module StereotypeIcon
          module_function

          def render(context)
            return nil unless context.classifier

            svg = Element::StereotypeIconRenderer.render(
              classifier: context.classifier,
              bounds: context.bounds,
              canvas: context.canvas
            )
            svg.empty? ? nil : svg
          end
        end
      end
    end
  end
end
